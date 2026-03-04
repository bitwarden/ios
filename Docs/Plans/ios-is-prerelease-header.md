# Plan: Add `Is-Prerelease` header to all API requests for Beta builds

## Goal

Send an `Is-Prerelease: 1` HTTP header on **every** API request made by the app **only when the running build is the Beta variant**. Production/App Store and Debug builds must not send the header (or send it only as required — see Open Questions on value/omission).

## Background & Key Findings

The codebase already has all the primitives needed; this is a small, well-contained change.

### 1. Where request headers are centrally added

`DefaultHeadersRequestHandler` (BitwardenKit) is the single `RequestHandler` that stamps common headers onto every outgoing request. It is shared by **both** apps (Password Manager and Authenticator).

- `BitwardenKit/Core/Platform/Services/API/Handlers/DefaultHeadersRequestHandler.swift:29-35`
  ```swift
  request.headers["Bitwarden-Client-Name"] = Constants.clientType
  request.headers["Bitwarden-Client-Version"] = appVersion
  request.headers["Device-Type"] = String(Constants.deviceType)
  request.headers["User-Agent"] = userAgentBuilder.value
  ```

This is the correct and only place to add the new header. Adding it here guarantees it applies to *all* `HTTPService` instances, since every service is built with this handler in its `requestHandlers` array:

- **Password Manager** builds all services via `HTTPServiceBuilder.makeService(...)`, whose `requestHandlers` array includes `defaultHeadersRequestHandler`.
  - `BitwardenKit/Core/Platform/Services/API/HTTPServiceBuilder.swift:70-84`
  - Covers: `apiService`, `apiUnauthenticatedService`, `eventsService`, `hibpService`, `identityService`, `fillAssistService`, `buildKeyConnectorService(baseURL:)`, and the identity service inside `DefaultAccountTokenProvider`.
  - `BitwardenShared/Core/Platform/Services/API/APIService.swift:74-118`
- **Authenticator** builds its one service directly, also with `defaultHeadersRequestHandler` in `requestHandlers`.
  - `AuthenticatorShared/Core/Platform/Services/API/APIService.swift:44-57`

> Note: `hibpService` targets `api.pwnedpasswords.com` (third party). Because the header goes on the shared handler, HIBP requests will also receive it. See Open Questions.

### 2. How a Beta build is detected

`AppInfoService.isBetaBuild` already exists in BitwardenKit and derives beta status from the bundle identifier suffix:

- `BitwardenKit/Core/Platform/Services/AppInfoService.swift:57` (protocol) and `:159-161` (impl)
  ```swift
  var isBetaBuild: Bool {
      bundle.bundleIdentifier?.hasSuffix(".beta") == true
  }
  ```
- Mock exists: `MockAppInfoService.isBetaBuild` (`BitwardenKit/Core/Platform/Services/Mocks/MockAppInfoService.swift:22`, default `false`).
- Precedent for consuming it: `ReviewPromptService` gates on `appInfoService.isBetaBuild` (`BitwardenShared/Core/Platform/Services/ReviewPromptService.swift:78`).

We will **not** reimplement beta detection. However, `DefaultHeadersRequestHandler` currently takes only `appVersion` + `userAgentBuilder` and does not depend on `AppInfoService`. To keep the handler decoupled and trivially testable, inject a **plain `Bool` (`isPrerelease`)** rather than the whole service (both live in BitwardenKit, so either is possible; a `Bool` keeps the handler's surface minimal and the tests simple).

### 3. Dependency wiring is already non-circular

In both containers, `appInfoService` is constructed **before** `apiService`, so we can read `isBetaBuild` at `APIService` init time and pass it down:

- PM: `BitwardenShared/.../ServiceContainer.swift:494` (appInfoService) then `:587` (apiService).
- Authenticator: `appInfoService` is available in its container before `apiService` at `AuthenticatorShared/.../ServiceContainer.swift:254`. (Verify the Authenticator container constructs an `AppInfoService`; if it does not, compute the flag inline from `Bundle.main` — see step 3b.)

## Header specification

- **Name:** `Is-Prerelease`
- **Value:** `"1"` when beta; header **omitted entirely** otherwise.
  - Rationale: matches the boolean/flag convention used server-side by other Bitwarden clients. Confirm exact name/value with the ticket/backend contract (Open Questions).

## Implementation Steps

### Step 1 — `DefaultHeadersRequestHandler`: accept and apply the flag

File: `BitwardenKit/Core/Platform/Services/API/Handlers/DefaultHeadersRequestHandler.swift`

1. Add a stored property `let isPrerelease: Bool`.
2. Add it to `init(...)` (place it before `userAgentBuilder` alphabetically or keep a sensible order; update the DocC parameter list).
3. In `handle(_:)`, after the existing headers, conditionally add:
   ```swift
   if isPrerelease {
       request.headers["Is-Prerelease"] = "1"
   }
   ```

### Step 2 — Password Manager `APIService`: thread the flag through

File: `BitwardenShared/Core/Platform/Services/API/APIService.swift`

1. Add an `isPrerelease: Bool` parameter to `APIService.init(...)` (default `false` to keep existing tests/call sites compiling; update DocC).
2. Pass it into the `DefaultHeadersRequestHandler(...)` constructor at `:76`.

File: `BitwardenShared/Core/Platform/Services/ServiceContainer.swift`

3. At the `APIService(...)` call (`:587`), pass `isPrerelease: appInfoService.isBetaBuild`.

### Step 3 — Authenticator `APIService`: thread the flag through

File: `AuthenticatorShared/Core/Platform/Services/API/APIService.swift`

1. Add `isPrerelease: Bool` parameter (default `false`) to `init(...)`; pass into `DefaultHeadersRequestHandler(...)` at `:44`.

File: `AuthenticatorShared/Core/Platform/Services/ServiceContainer.swift`

2. At the `APIService(...)` call (`:254`), pass `isPrerelease: appInfoService.isBetaBuild`.

**Step 3b (fallback):** If the Authenticator container does not already build an `AppInfoService`, either:
- construct a `DefaultAppInfoService(configServiceProvider: { nil })` locally and read `.isBetaBuild`, or
- compute inline: `Bundle.main.bundleIdentifier?.hasSuffix(".beta") == true`.
Prefer reusing `AppInfoService` for consistency with PM.

### Step 4 — Tests

**`DefaultHeadersRequestHandlerTests`** (`BitwardenKit/Core/Platform/Services/API/Handlers/DefaultHeadersRequestHandlerTests.swift`)
- Existing `test_handleRequest_addsDefaultHeaders` currently builds the subject with only `appVersion`/`userAgentBuilder`; update the initializer call to pass `isPrerelease:`.
- Split/extend coverage:
  - `test_handleRequest_prerelease_addsIsPrereleaseHeader`: subject built with `isPrerelease: true` → assert `headers["Is-Prerelease"] == "1"`.
  - `test_handleRequest_notPrerelease_omitsIsPrereleaseHeader`: subject built with `isPrerelease: false` → assert `headers["Is-Prerelease"] == nil`.
  - Keep asserting the four existing headers are unaffected in both cases.

**`APIService` tests (PM & Authenticator)**
- If there are existing `APIService` init tests, add a case constructing with `isPrerelease: true` and asserting an outgoing request through a mocked client carries `Is-Prerelease`. (Follow the existing `MockHTTPClient` pattern in `Networking` tests / the app's API test suites.)

**Container-level (optional, if such tests exist)**
- Verify `ServiceContainer` passes `appInfoService.isBetaBuild` through — usually covered indirectly; not required if `APIService`/handler tests are solid.

Follow `Docs/Testing.md` and the `testing-ios-code` skill. Test naming: `test_<functionName>_<behaviorDescription>`.

## Files to change

| File | Change |
|------|--------|
| `BitwardenKit/Core/Platform/Services/API/Handlers/DefaultHeadersRequestHandler.swift` | Add `isPrerelease` prop + init param; conditionally set header |
| `BitwardenShared/Core/Platform/Services/API/APIService.swift` | Add `isPrerelease` init param; pass to handler |
| `BitwardenShared/Core/Platform/Services/ServiceContainer.swift` | Pass `appInfoService.isBetaBuild` into `APIService` |
| `AuthenticatorShared/Core/Platform/Services/API/APIService.swift` | Add `isPrerelease` init param; pass to handler |
| `AuthenticatorShared/Core/Platform/Services/ServiceContainer.swift` | Pass beta flag into `APIService` (see 3b) |
| `BitwardenKit/Core/Platform/Services/API/Handlers/DefaultHeadersRequestHandlerTests.swift` | Update + add prerelease header tests |
| (optional) PM/Authenticator `APIServiceTests` | End-to-end header assertion |

No new files, no new top-level `Core/`/`UI/` subdirectories, no CoreData/keychain changes. No Sourcery/mock regeneration needed (`MockAppInfoService.isBetaBuild` already exists; the handler is a concrete class, not a protocol).

## Why this approach (vs. alternatives)

- **Modify `DefaultHeadersRequestHandler` (chosen):** single choke point, applies to both apps and all services automatically, matches existing header conventions, trivially unit-testable.
- **New dedicated `PrereleaseRequestHandler` added to each `requestHandlers` array (rejected):** more files, must be wired into both `HTTPServiceBuilder` and the Authenticator's direct `HTTPService(...)`, easy to forget a service; no real benefit over folding one line into the existing handler.
- **Set the header per-`Request` model (rejected):** would require touching every request type and is impossible to keep exhaustive.

## Open Questions (confirm before/while implementing)

1. **Exact header name & value.** Confirm the backend contract: is it literally `Is-Prerelease`? Value `"1"` vs `"true"` vs presence-only? Align with other Bitwarden clients / the Jira ticket.
2. **HIBP + third-party hosts.** The shared handler will also stamp `Is-Prerelease` on the `hibpService` request to `api.pwnedpasswords.com` (and any non-Bitwarden host). Confirm this is acceptable; if not, scope the header to Bitwarden hosts only (would require host-aware logic in the handler, similar to `SSOCookieVendorRequestHandler`).
3. **Debug builds.** `isBetaBuild` is false for Debug/local builds (bundle id lacks `.beta`). Confirm Debug builds should NOT send the header. If dev/debug should be treated as prerelease, adjust the flag source accordingly.
4. **Authenticator scope.** Confirm the header is wanted for the Authenticator app too, not only Password Manager. This plan includes it for both; drop Step 3 if PM-only.

## Verification

- `mint run swiftformat .` and `mint run swiftlint` clean.
- Build both apps (`build-test-verify` skill).
- Run the updated handler tests; confirm header present only when `isPrerelease: true`.
- Manual/staging check: run a Beta build, inspect an outgoing request (flight recorder / proxy) for `Is-Prerelease: 1`; run a Debug/Release build and confirm it is absent.
