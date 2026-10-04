# hermes-council

A council of [Hermes Agent](https://hermes-agent.nousresearch.com) profiles that explores a web dashboard with Playwright, maps every page and feature, and explains how the features link together. Members work independently, a verifier cross-checks them against the live dashboard, and a chair writes the final report.

Each member runs on a different model family (set in `council.conf`) so no single model's blind spots dominate.

| Member | Model (OpenRouter) | Job |
|---|---|---|
| cartographer | `z-ai/glm-5.3-flash` | Inventory every page and feature |
| linker | `deepseek/deepseek-v4-pro` | Map relationships: navigation, shared entities, data flows, shared APIs |
| verifier | `openai/gpt-5.6-luna` | Cross-check both reports in the live dashboard, rule on disagreements |
| chair | `qwen/qwen3.8-max-0902` | Write `output/FINAL_REPORT.md` |

## Requirements

Hermes Agent, Node.js 20+, and an OpenRouter API key.

## Setup on a new machine

```bash
git clone git@github.com:ibefehdi/hermes-council.git ~/council && cd ~/council
./setup.sh
```

`setup.sh` installs Playwright and Chromium, creates the four Hermes profiles, sets their models from `council.conf`, registers the Playwright MCP server, and asks for the dashboard login and OpenRouter key. Secrets go to `.env` and the profiles' own `.env` files, never into git. Re-run it any time after editing `council.conf` or pulling changes.

## Run

```bash
./run-council.sh                                  # whole dashboard
./run-council.sh "Focus on billing and reports"   # narrower run
```

The script checks the saved session in `auth.json`. If it's missing or expired, it logs in: automatically when `DASHBOARD_PASS` is set, otherwise (OTP, SSO, 2FA, CAPTCHA) it opens a browser where you log in yourself and saves the session as soon as the dashboard loads. Every agent reuses that session, so neither the password nor the OTP ever reaches the models. It then starts the Hermes gateway if needed and launches the swarm. The report lands in `output/FINAL_REPORT.md`; previous runs are moved to `runs/`.

To refresh the session by hand: `npm run login:headed`. To test it: `node login.mjs --check`.

## Safety

Agents are told the target is staging: they may click anything, but created records are prefixed `COUNCIL-TEST`, existing records are never modified or deleted, and the final report lists everything to clean up. Do not point it at production.
