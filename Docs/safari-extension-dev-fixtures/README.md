# Safari Extension Dev Fixtures

These fixture pages make Safari Web Extension work reproducible without depending on a live external site.

## Included pages

- `login.html`
  - visible username + password
  - for fill and update-existing-login checks
- `signup.html`
  - visible email + new/confirm password
  - for generated-password → save-new-login checks
- `change-password.html`
  - current + new/confirm password
  - for generated-password → update-password checks

## Start a local fixture server

From repo root:

```bash
cd ~/_dev/ios
python3 -m http.server 8123 -d Docs/safari-extension-dev-fixtures
```

Then open one of these URLs on the booted simulator:

- `http://127.0.0.1:8123/login.html`
- `http://127.0.0.1:8123/signup.html`
- `http://127.0.0.1:8123/change-password.html`

If Safari is opening for the first time on that simulator, dismiss its onboarding/search-engine prompt once before expecting the fixture page to appear immediately.

## Open in the booted simulator from Terminal

```bash
xcrun simctl openurl booted http://127.0.0.1:8123/signup.html
xcrun simctl openurl booted http://127.0.0.1:8123/change-password.html
xcrun simctl openurl booted http://127.0.0.1:8123/login.html
```

## Recommended local loop

1. Run the fast JS/Swift verification commands for the slice you are editing.
2. Build the Safari extension target.
3. Open one fixture page in Simulator Safari.
4. Use Safari Web Inspector to inspect field classification and bridge payloads.
5. Repeat on the next fixture page.

## With `serve-sim`

`serve-sim` is useful when you want AI/browser/remote control of the simulator.

Example:

```bash
npx serve-sim --detach
open http://localhost:3200
```

Use it as a visibility/control layer, not a replacement for Safari Web Inspector.

Troubleshooting:
- `serve-sim --help` may work even when the streaming helper cannot launch.
- If the helper fails to load `SimulatorKit.framework`, verify that your Xcode installation is discoverable at the standard private-framework location expected by the tool.
- A versioned Xcode app path such as `/Applications/Xcode-26.4.1.app` can require extra environment alignment or an upstream fix before `serve-sim` is usable.

## With Maestro

The `.maestro/` flows in this repo assume the same fixture server is running on port `8123`.

Suggested order:

1. Verify the page manually in Simulator Safari.
2. Confirm the Safari extension behavior manually once.
3. Only then run the matching Maestro smoke flow.

Prerequisites from the official Maestro CLI docs:
- Java 17+
- current Xcode / Command Line Tools on macOS

Official install options:

```bash
curl -fsSL "https://get.maestro.mobile.dev" | bash
```

or

```bash
brew tap mobile-dev-inc/tap
brew install mobile-dev-inc/tap/maestro
```

## Why these fixtures exist

They keep the main path simple:

- no external site flakiness
- no login anti-bot noise
- stable labels and form actions
- easy reuse for Web Inspector, `serve-sim`, screenshots, and Maestro smoke checks
