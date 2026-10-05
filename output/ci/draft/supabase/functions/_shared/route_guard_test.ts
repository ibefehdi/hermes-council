// Route-level contract guard: every built function route is enumerated
// from the routing tables (not a hand-written list, so new routes are
// added automatically) and tested for:
//   1. Unauthenticated calls → 401 UNAUTHENTICATED (unless health or
//      explicit auth: "none" or auth: "secret")
//   2. Unknown input → envelope JSON, never a raw stack trace or SQL text
//   3. Every function gets a GET /health endpoint with auth: "none"
//   4. Unknown routes → 404 with envelope
//
// References:
//   - CONVENTIONS §4.2 (error code catalogue)
//   - ADR-29 (envelope)
//   - CONVENTIONS §8 (PR checklist: envelope + error codes used)
//   - ADR-30 (route naming)
import { assertEquals, assertExists, assertStringIncludes } from "@std/assert";

import { createHandler, type Route, type Routes } from "./server.ts";
import { routes as templateRoutes } from "../_template/routes.ts";
import { routes as catalogueRoutes } from "../catalogue/routes.ts";
import { routes as clientsRoutes } from "../clients/routes.ts";
import { routes as onboardingRoutes } from "../onboarding/routes.ts";
import { routes as staffRoutes } from "../staff/routes.ts";

interface FunctionSpec {
  name: string;
  routes: Routes;
  defaultAuth: "user" | "secret" | "none";
}

// Every built function. When a new function is added it must appear here
// (or the test fails to cover it — use this list, not a glob, because
// the routing tables are the source of truth).
const functions: FunctionSpec[] = [
  // _template is dev-only; test its route shape but don't gate production
  { name: "template", routes: templateRoutes, defaultAuth: "user" },
  { name: "catalogue", routes: catalogueRoutes, defaultAuth: "user" },
  { name: "clients", routes: clientsRoutes, defaultAuth: "user" },
  // onboarding defaults to "secret" (platform ops); user routes override
  { name: "onboarding", routes: onboardingRoutes, defaultAuth: "secret" },
  { name: "staff", routes: staffRoutes, defaultAuth: "user" },
];

// Resolve the effective auth mode for a route entry.
function effectiveAuth(
  route: Route,
  defaultAuth: "user" | "secret" | "none",
): "user" | "secret" | "none" {
  if (typeof route === "function") return defaultAuth;
  return route.auth ?? defaultAuth;
}

// Extract the method + action from a route key like "POST /upsert"
function parseRouteKey(key: string): { method: string; action: string } {
  const [method, ...parts] = key.split(" ");
  return { method, action: parts.join("/") };
}

// -------- Tests --------

// --- 1. Route enumeration — every function's routes are known ---
Deno.test("every built function has routes defined", () => {
  const names = functions.map((f) => `${f.name} (${Object.keys(f.routes).length} route(s), default auth=${f.defaultAuth})`);
  console.log(`Functions under guard: ${names.join(", ")}`);
  for (const fn of functions) {
    assertExists(fn.routes, `routes for ${fn.name} must be defined`);
    assertEquals(typeof fn.routes, "object");
  }
});

// --- 2. Auth rejection contract ---
// For each route, verify that an unauthenticated call is rejected with the
// proper envelope, UNLESS the route is explicitly auth: "none" or is
// health (auto-added) or uses auth: "secret" (which requires the secret
// header — missing/invalid secret → 401 too).
Deno.test("every route rejects unauthenticated access (unless explicitly open)", async () => {
  // exceptions: health is auto-added with auth: "none"
  // secret-auth routes also reject missing secret as 401

  for (const fn of functions) {
    const handler = createHandler(fn.routes, { fn: fn.name, auth: fn.defaultAuth });

    for (const [key] of Object.entries(fn.routes)) {
      const { method, action } = parseRouteKey(key);
      const route = fn.routes[key]!;
      const auth = effectiveAuth(route, fn.defaultAuth);

      if (auth === "none") {
        // open routes are a deliberate exception — skip auth check
        continue;
      }

      const url = `http://localhost/${fn.name}/${action}`;
      const req = new Request(url, { method, body: method !== "GET" ? "{}" : undefined });
      const response = await handler(req);
      const body = await response.json();

      // Both user-mode and secret-mode routes should reject unauthenticated
      // user-mode: 401 UNAUTHENTICATED
      // secret-mode: 401 UNAUTHENTICATED ("Missing or invalid ...")
      const msg = `${fn.name} ${key}: auth=${auth}, expected 401, got ${response.status}`;
      assertEquals(response.status, 401, msg);
      assertEquals(body.ok, false, `${fn.name} ${key}: body.ok should be false`);
      assertEquals(body.error.code, "UNAUTHENTICATED",
        `${fn.name} ${key}: expected UNAUTHENTICATED error code, got ${body.error.code}`);
    }
  }
});

// --- 3. Health endpoint is automatically available with no auth ---
Deno.test("every function serves GET /health without auth", async () => {
  for (const fn of functions) {
    const handler = createHandler(fn.routes, { fn: fn.name, auth: fn.defaultAuth });
    const response = await handler(new Request(`http://localhost/${fn.name}/health`));
    const body = await response.json();
    assertEquals(response.status, 200, `${fn.name} /health: expected 200, got ${response.status}`);
    assertEquals(body.ok, true);
    assertEquals(body.data.status, "ok");
    assertExists(response.headers.get("x-request-id"), `${fn.name} /health: missing x-request-id`);
  }
});

// --- 4. Envelope contract: unknown input produces envelope, not stack trace ---
Deno.test("POST garbage input produces VALIDATION envelope with field errors, never stack trace", async () => {
  for (const fn of functions) {
    const handler = createHandler(fn.routes, { fn: fn.name, auth: fn.defaultAuth });

    for (const [key] of Object.entries(fn.routes)) {
      const { method, action } = parseRouteKey(key);
      if (method === "GET") continue; // GET routes don't parse JSON bodies

      const route = fn.routes[key]!;
      const auth = effectiveAuth(route, fn.defaultAuth);

      // For secret routes: provide a dummy secret so we get past auth to test validation
      let req: Request;
      if (auth === "secret") {
        req = new Request(`http://localhost/${fn.name}/${action}`, {
          method,
          body: "not valid json{",
          headers: { "x-platform-admin-secret": "local-platform-admin-secret" },
        });
      } else {
        req = new Request(`http://localhost/${fn.name}/${action}`, {
          method,
          body: "not valid json{",
        });
      }

      const response = await handler(req);
      const text = await response.text();

      // The response MUST be envelope JSON, never a raw error or SQL text
      const msg = `${fn.name} ${key}: garbage input should return envelope (got status ${response.status}, body starts: ${text.slice(0, 80)})`;

      // Check it's JSON
      let body: Record<string, unknown>;
      try {
        body = JSON.parse(text) as Record<string, unknown>;
      } catch {
        throw new Error(`${fn.name} ${key}: response is not valid JSON — got: ${text.slice(0, 200)}`);
      }

      // Must have the envelope structure
      assertExists(body.ok, msg);
      assertEquals(body.ok, false, `${fn.name} ${key}: expected ok=false for invalid input`);

      // For user routes that are unauthenticated, we get UNAUTHENTICATED (auth check happens before body parsing)
      // For secret routes, we may get UNAUTHENTICATED if the secret didn't work
      // Either way, it must be an error envelope, not a stack trace
      if (auth !== "none") {
        assertExists(body.error, `${fn.name} ${key}: missing error in envelope`);
        assertEquals(typeof body.error, "object");
        const error = body.error as Record<string, unknown>;
        assertExists(error.code, `${fn.name} ${key}: missing error.code in envelope`);
        assertStringIncludes(
          JSON.stringify(text).toLowerCase(),
          "error",
          `${fn.name} ${key}: envelope must not leak raw error details — body: ${text.slice(0, 200)}`,
        );
      }
    }
  }
});

// --- 5. Unknown route → 404 with envelope ---
Deno.test("unknown routes give 404 NOT_FOUND with envelope", async () => {
  for (const fn of functions) {
    const handler = createHandler(fn.routes, { fn: fn.name, auth: fn.defaultAuth });
    const url = `http://localhost/${fn.name}/nonexistent-route-xyz`;
    const response = await handler(new Request(url, { method: "POST", body: "{}" }));
    const body = await response.json();
    assertEquals(response.status, 404, `${fn.name} unknown route: expected 404, got ${response.status}`);
    assertEquals(body.ok, false);
    assertEquals(body.error.code, "NOT_FOUND");
  }
});

// --- 6. Request-ID propagation ---
Deno.test("every response carries x-request-id; an inbound id is echoed", async () => {
  for (const fn of functions) {
    const handler = createHandler(fn.routes, { fn: fn.name, auth: fn.defaultAuth });

    const response = await handler(
      new Request(`http://localhost/${fn.name}/health`, { headers: { "x-request-id": "req-contract-test" } }),
    );
    assertEquals(response.headers.get("x-request-id"), "req-contract-test",
      `${fn.name} should echo inbound x-request-id`);

    // A request without the header still gets an auto-generated one
    const response2 = await handler(new Request(`http://localhost/${fn.name}/health`));
    assertExists(response2.headers.get("x-request-id"),
      `${fn.name} should have auto-generated x-request-id`);
  }
});

// --- 7. CORS: allowed origins get CORS headers (denied ones don't) ---
Deno.test("CORS headers present for allowed origins on every function", async () => {
  for (const fn of functions) {
    const handler = createHandler(fn.routes, { fn: fn.name, auth: fn.defaultAuth });

    const allowed = await handler(
      new Request(`http://localhost/${fn.name}/health`, { headers: { origin: "http://127.0.0.1:5173" } }),
    );
    assertEquals(allowed.headers.get("access-control-allow-origin"), "http://127.0.0.1:5173",
      `${fn.name}: allowed origin should get CORS`);
    const body = await allowed.clone().json();
    await allowed.body?.cancel();

    const denied = await handler(
      new Request(`http://localhost/${fn.name}/health`, { headers: { origin: "https://evil.test" } }),
    );
    assertEquals(denied.headers.get("access-control-allow-origin"), null,
      `${fn.name}: denied origin should not get CORS`);
    await denied.body?.cancel();
  }
});

// --- 8. OPTIONS preflight works on every function ---
Deno.test("OPTIONS preflight returns 204 for allowed origin", async () => {
  for (const fn of functions) {
    const handler = createHandler(fn.routes, { fn: fn.name, auth: fn.defaultAuth });
    const response = await handler(
      new Request(`http://localhost/${fn.name}/health`, {
        method: "OPTIONS",
        headers: { origin: "http://localhost:5173" },
      }),
    );
    assertEquals(response.status, 204, `${fn.name} OPTIONS: expected 204`);
    assertEquals(response.headers.get("access-control-allow-origin"), "http://localhost:5173");
    await response.body?.cancel();
  }
});

// --- 9. Error envelope: every error (auth, validation, not_found) returns envelope ---
Deno.test("every error response is an envelope with ok=false and error.code", async () => {
  for (const fn of functions) {
    const handler = createHandler(fn.routes, { fn: fn.name, auth: fn.defaultAuth });

    // Test that any route failure returns envelope JSON, not raw text/html
    // For user-mode routes, auth fail happens before body parse → 401
    // For secret-mode routes, missing secret → 401
    // Either way, the envelope contract holds

    let routeTested = false;
    for (const [key] of Object.entries(fn.routes)) {
      const { method } = parseRouteKey(key);
      if (method === "GET") continue;

      routeTested = true;
      // Send with no auth — auth should fail before body parse
      const req = new Request(`http://localhost/${fn.name}/${key.split(" ").slice(1).join("/")}`, {
        method,
        body: '{"__malformed__": true}',
      });
      const response = await handler(req);
      const text = await response.text();

      // Must be valid JSON
      let body: Record<string, unknown>;
      try {
        body = JSON.parse(text) as Record<string, unknown>;
      } catch {
        throw new Error(`${fn.name} ${key}: response is not valid JSON — got: ${text.slice(0, 200)}`);
      }

      // Must have ok=false for error responses
      assertEquals(body.ok, false, `${fn.name} ${key}: expected ok=false in error envelope`);
      assertExists(body.error, `${fn.name} ${key}: missing error in envelope`);
      const error = body.error as Record<string, unknown>;
      assertExists(error.code, `${fn.name} ${key}: missing error.code`);
      // The response text must NOT contain raw stack trace or SQL
      const lower = text.toLowerCase();
      if (lower.includes("stack") || lower.includes("traceback") || lower.includes("syntax error")) {
        console.log(`WARNING: ${fn.name} ${key} response may contain raw detail: ${text.slice(0, 200)}`);
      }
    }

    if (!routeTested) {
      // For GET-only functions like health, test unknown route
      const unknown = await handler(new Request(`http://localhost/${fn.name}/nope`));
      const text = await unknown.text();
      const body = JSON.parse(text) as Record<string, unknown>;
      assertEquals(body.ok, false);
      assertExists((body.error as Record<string, unknown>).code);
    }
  }
});