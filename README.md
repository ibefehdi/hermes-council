# hermes-council

A council of [Hermes Agent](https://hermes-agent.nousresearch.com) profiles that explores a web dashboard with Playwright, maps every page and feature, and explains how the features link together. Members work independently, a verifier cross-checks them against the live dashboard, and a chair writes the final report.

| Member | Default model | Job |
|---|---|---|
| cartographer | local Qwen if reachable, else `deepseek/deepseek-v4-flash` | Inventory every page and feature |
| linker | `deepseek/deepseek-v4-pro` | Map relationships: navigation, shared entities, data flows, shared APIs |
| verifier | `moonshotai/kimi-k3` | Cross-check both reports in the live dashboard, rule on disagreements |
| chair | `deepseek/deepseek-v4-pro` | Write `output/FINAL_REPORT.md` |

## Requirements

Hermes Agent, Node.js 20+, and an OpenRouter API key.

## Setup on a new machine

```bash
git clone git@github.com:fahadasnan/hermes-council.git ~/council && cd ~/council
./setup.sh
```

`setup.sh` installs Playwright and Chromium, creates the four Hermes profiles, sets their models from `council.conf`, registers the Playwright MCP server, and asks for the dashboard login and OpenRouter key. Secrets go to `.env` and the profiles' own `.env` files, never into git. Re-run it any time after editing `council.conf` or pulling changes.

## Run

```bash
./run-council.sh                                  # whole dashboard
./run-council.sh "Focus on billing and reports"   # narrower run
```

The script logs in, saves the session to `auth.json` (agents reuse it, so the password never reaches the models), starts the Hermes gateway if needed, and launches the swarm. The report lands in `output/FINAL_REPORT.md`; previous runs are moved to `runs/`.

If the login page needs SSO, 2FA, or a CAPTCHA, log in manually once with `npm run login:headed`.

## Safety

Agents are told the target is staging: they may click anything, but created records are prefixed `COUNCIL-TEST`, existing records are never modified or deleted, and the final report lists everything to clean up. Do not point it at production.
