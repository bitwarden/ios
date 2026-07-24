# Maestro smoke flows for Safari extension fixtures

These flows are intentionally small and assume you are using the local fixture pages in `Docs/safari-extension-dev-fixtures/`.

## Prerequisites

1. Start the local fixture server:

```bash
cd ~/_dev/ios
python3 -m http.server 8123 -d Docs/safari-extension-dev-fixtures
```

2. Ensure the iOS simulator is booted.
3. Ensure Safari's first-run onboarding has already been dismissed on that simulator.
4. Install Maestro CLI according to the official docs:

```bash
curl -fsSL "https://get.maestro.mobile.dev" | bash
```

or

```bash
brew tap mobile-dev-inc/tap
brew install mobile-dev-inc/tap/maestro
```

## Run a smoke flow

```bash
maestro test .maestro/safari-login-smoke.yaml
maestro test .maestro/safari-signup-smoke.yaml
maestro test .maestro/safari-change-password-smoke.yaml
```

These Maestro flows verify the local page/fixture wiring only. Bitwarden-specific extension behavior (credential matching, suggestion display, save/update, and Safari permissions) is covered by the `BitwardenUITests` feasibility flows and manual Safari QA; those require a logged-in local environment and are not suitable for an unauthenticated page smoke.

## Intended use

These are not full product regressions yet. They are a lightweight starting point for:
- opening the stable local fixture page
- proving simulator + Safari + CLI wiring works
- growing toward richer Safari extension E2E checks later
