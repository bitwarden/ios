---
name: evaluating-sdk-internal-updates
description: Evaluates a bitwarden/ios "Update SDK to" PR against the sdk-swift commit range for compile-time, runtime and serialization breaking changes, maps affected symbols to iOS call sites, and applies clear in-scope fixes. Use when reviewing an SDK bump PR, a BitwardenSdk revision change in project-common.yml, or triaging sdk-internal breaking changes.
allowed-tools:
  - Bash(gh pr diff:*)
  - Bash(xcrun xcodebuild *)
  - Bash(bash .claude/skills/evaluating-sdk-internal-updates/sdk-surface-diff.sh *)
  - Bash(git -C * diff *)
  - Bash(git grep:*)
  - Bash(grep:*)
  - Bash(git add:*)
  - Bash(git commit:*)
  - Read
  - Grep
  - Glob
  - Edit
  - Write
  - Skill(implementing-ios-code)
  - Skill(bitwarden-delivery-tools:committing-changes)
---

# Evaluating sdk-internal Updates

**Read the build before crawling, and survey the whole range before fixing anything.** A failing build locates a compile break more precisely than any diff; the binding diff finds what compiles clean and breaks at runtime. Steps 3-8 complete before step 9 starts.

## Identify

iOS pins a `bitwarden/sdk-swift` revision, not `sdk-internal`, and sdk-swift commits its generated UniFFI Swift. That is both the source iOS compiles against and the diffable record of the API change; use sdk-internal only to explain why something changed. Every crate flattens into one `BitwardenSdk` target, so a type moving between generated files is a Kotlin import break and an iOS no-op — never report one. The iOS-only hazard is the reverse: a new name colliding with an existing one. sdk-swift's `main` is months behind; releases live on `unstable` and `v<version>` tags.

1. `gh pr diff <PR> -R bitwarden/ios` → the old and new `revision:` lines in `project-common.yml`. The SHA is an sdk-swift revision; the trailing comment is `<semver>-<ci-run>-<sdk-internal-short-sha>`. Take the pin from the PR diff or a fresh fetch, not from a local `origin/sdlc/sdk-update` ref, which is long-lived and force-updated, so a stale copy shows a version no longer on the branch. A pure bump touches only that file and `Bitwarden.xcworkspace/xcshareddata/swiftpm/Package.resolved`; that file's unchanged `originHash` and the untracked `BitwardenKit.xcodeproj/.../Package.resolved` are not findings.
2. Locate the sdk-swift clone in a sibling directory — `../sdk-swift` alongside this repo, which is where CI places it. If there is none, stop and tell the user it is a required prerequisite; do not clone it. sdk-internal (`../sdk-internal`) is optional, needed only for step 5.
3. Get a build of both apps. **In CI the build has already run and the prompt names its log; grep that log with the filter below and treat the result as this step's output. Do not build.** A cold build of both schemes exceeds the ceiling on a single command, so building here is not an option that merely costs time. Everything else in this step is the local path, and step 10 needs the invocation regardless. Every `xcodebuild` invocation in this skill — here and in step 10 — takes the same destination: CI exports `_SIMULATOR_ID` for an already-booted simulator, and outside CI there is none, so substitute `name=$(tr -d '\n' < .test-simulator-device-name),OS=$(tr -d '\n' < .test-simulator-ios-version)` for `id=$_SIMULATOR_ID` in both blocks. Avoid `generic/platform=iOS Simulator`, which also builds x86_64 for no extra signal.
   ```bash
   xcrun xcodebuild build-for-testing -workspace Bitwarden.xcworkspace -scheme Bitwarden \
     -configuration Debug -destination "platform=iOS Simulator,id=$_SIMULATOR_ID" \
     -derivedDataPath build/DerivedData -parallelizeTargets \
     -skipPackagePluginValidation -skipMacroValidation -quiet 2>&1 \
     | grep -E ' error:|BUILD|Undefined symbols|^ld:'
   ```
   Repeat with `-scheme Authenticator`. Use `build-for-testing`, not `build`: `BitwardenSdkMocks` is reachable only from test targets, and a renamed protocol breaks there first. The filter carries `Undefined symbols` and `^ld:` because a link failure is reported by neither ` error:` nor `BUILD`, and a symbol-level break is exactly what this skill exists to catch; on any `BUILD FAILED` with no cause above it, read around the failure in the CI log, or re-run unfiltered locally. The CI log holds both schemes, each bracketed by `=== <scheme> ===` and `=== <scheme> exit=<code> ===`; those two markers are how a build that ran clean is distinguished from one that never started, so treat their absence as an error rather than as a pass. `./Scripts/bootstrap.sh` must have run first: the `.xcodeproj` files are generated, and a stale one omits sources and reports `cannot find 'X' in scope`, which mimics an SDK break. Note any failure and continue — a clean build rules out compile breaks only.
4. From the repo root, `bash .claude/skills/evaluating-sdk-internal-updates/sdk-surface-diff.sh <sdk-swift-path> <old> <new>` prints RANGE, REMOVED, ADDED and MUTATED. MUTATED compares type declaration lines only, so `--decls` is the only view of a signature change on any function or method, and `--type <TypeName>` the only view of a type's members or its initializer. A reordered record field appears in no section, since initializers are excluded and both sides of `--decls` are sorted; step 3's build is the only gate for it. Enum cases and protocol requirements take no access modifier, so they reach no section and no `--decls` hunk either: a case added to an enum that already existed is visible only through `--type`, and a `default:` clause at the call site hides it from step 3 as well, so run `--type` against every enum and protocol the RANGE commits touch. ADDED lists `<kind> <name>`, so an added field can hide behind the same field name on another type, and only a pre-existing owner is a break. RANGE is oldest-first, and its `base:` line carries the old sdk-internal SHA that `OLD..NEW` excludes and step 5 needs.
5. `git -C <sdk-internal> diff <old-sha>..<new-sha> -- '*/uniffi.toml'`. Only `bitwarden-core` and `bitwarden-crypto` set `generate_codable_conformance`, so a type moving to any other crate silently loses `Codable`, which is a serialization break with no compile signal. Error enums come from `#[bitwarden_error(flat)]` rather than `derive(uniffi::Error)`, so grepping for `uniffi::` misses the entire error surface.
6. For each symbol from steps 4-5, `git grep -n '<Symbol>' -- '*.swift'` from the repo root. No module list and no import-prefix filter: everything arrives via plain `import BitwardenSdk`, and both apps consume it, so `AuthenticatorShared` is not optional. Use `git grep` rather than `grep -r`, which also searches the SDK checkout step 3 left under gitignored `build/` and reports its own bindings as call sites. A surface change stays a candidate until a call site makes it a finding. A new protocol requirement has no symbol to grep yet, so grep the concept and check the hand-written `with_foreign` conformers: `Fido2CredentialStore`, `ClientManagedTokens`, `ServerCommunicationConfigRepository`, `Fido2UserInterface`.
7. Two gates a green build passes through. `grep -A3 'BitwardenSdk:' project-common.yml`: `SDKVersionInfoTests` asserts the trailing comment against `^\d+\.\d+\.\d+-\d+-[a-f0-9]+$`, and a leading `v` fails it, meaning the bump was dispatched with the tag name instead of the release name. Then `grep -n 'extension ' BitwardenSdkMocks/BitwardenSdkMocks.swift`: Sourcery cannot annotate external-module types, so that hand-maintained list is the only diff evidence of a protocol rename. Add an entry for a new client protocol iOS actually consumes, and never edit the generated mocks.
8. Report under these headings, which are the same across every repo running this evaluation: `## SDK bump evaluated`, `## Compile-time breaks`, `## Runtime considerations` (serialization findings go here; omit the heading when there are none), `## Everything else in range — confirmed safe`, `## Commit`. Give each finding its commit, symbol and call sites, and state whether the build passed inside `## Compile-time breaks` rather than as its own section. Cite sdk-internal commits and PRs as `bitwarden/sdk-internal#<N>` or a full URL; a bare `#<N>` copied from a commit subject auto-links into bitwarden/ios and tags an unrelated PR.

## Resolve

9. Fix anything found, compile-time or runtime, whenever the correct behavior is clear and in scope. For a new required method with no existing consumer, stub it: an empty body with a `// no-op` comment, or a `nil`/default return. Never `fatalError()`, `preconditionFailure()`, `try!` or a force-unwrap, which turn a stub into a crash. A sibling's structure is a template; its behavior is not evidence for yours. If unsure, report it instead of guessing, along with anything needing a product decision. Invoke `Skill(implementing-ios-code)` first if the fix is not mechanical, then commit with `Skill(bitwarden-delivery-tools:committing-changes)`.
10. Build both schemes yourself with step 3's command, then spot-test the test targets of the modules you edited, mapped with the table in `fixing-flaky-tests` step 2. Unlike step 3, run this one even in CI: it is incremental against the derived data the baseline left warm, so it finishes well inside the timeout.
    ```bash
    xcrun xcodebuild test-without-building -workspace Bitwarden.xcworkspace -scheme Bitwarden \
      -configuration Debug -destination "platform=iOS Simulator,id=$_SIMULATOR_ID" \
      -derivedDataPath build/DerivedData -only-testing:BitwardenSharedTests 2>&1 \
      | grep -E 'Executed|Suite .* (passed|failed)| error:'
    ```
    Filter at target level; the XCTest `Target/Class` form matches no Swift Testing suite. `xcodebuild` exits 0 when a filter matches nothing, so confirm the run happened rather than trusting the exit code: XCTest prints `Executed <N> tests`, which must be non-zero, while Swift Testing prints no such line, so for a Swift Testing target look for its `Suite ... passed` line instead. Two targets override the table: `BitwardenKitTests` and `NetworkingTests` are test targets of the `Bitwarden` scheme and appear in `TestPlans/Bitwarden-Default.xctestplan`, its default plan, so run them from `Bitwarden` with the command above rather than the `BitwardenKit` scheme the table names.
