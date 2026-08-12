---
name: evaluating-sdk-internal-updates
description: Evaluates a bitwarden/ios "Update SDK to" PR against the sdk-swift commit range for compile-time, runtime and serialization breaking changes, maps affected symbols to iOS call sites, and applies clear in-scope fixes. Use when reviewing an SDK bump PR, a BitwardenSdk revision change in project-common.yml, or triaging sdk-internal breaking changes.
---

# Evaluating sdk-internal Updates

**Build before crawling, and survey the whole range before fixing anything.** A failing build locates a compile break more precisely than any diff; the binding diff finds what compiles clean and breaks at runtime. Steps 3-8 complete before step 9 starts.

## Identify

iOS pins a `bitwarden/sdk-swift` revision, not `sdk-internal`, and sdk-swift commits its generated UniFFI Swift. That is both the source iOS compiles against and the diffable record of the API change; use sdk-internal only to explain why something changed. Every crate flattens into one `BitwardenSdk` target, so a type moving between generated files is a Kotlin import break and an iOS no-op — never report one. The iOS-only hazard is the reverse: a new name colliding with an existing one. sdk-swift's `main` is months behind; releases live on `unstable` and `v<version>` tags.

1. `gh pr diff <PR> -R bitwarden/ios` → the old and new `revision:` lines in `project-common.yml`. The SHA is an sdk-swift revision; the trailing comment is `<semver>-<ci-run>-<sdk-internal-short-sha>`. Take the pin from the PR diff or a fresh fetch, not from a local `origin/sdlc/sdk-update` ref, which is long-lived and force-updated, so a stale copy shows a version no longer on the branch. A pure bump touches only that file and `Bitwarden.xcworkspace/xcshareddata/swiftpm/Package.resolved`; that file's unchanged `originHash` and the untracked `BitwardenKit.xcodeproj/.../Package.resolved` are not findings.
2. Locate the sdk-swift clone in a sibling directory. If there is none, stop and tell the user it is a required prerequisite; do not clone it. sdk-internal is optional, needed only for step 5.
3. Build both apps:
   ```bash
   xcrun xcodebuild build-for-testing -workspace Bitwarden.xcworkspace -scheme Bitwarden \
     -configuration Debug -destination "platform=iOS Simulator,id=$_SIMULATOR_ID" \
     -derivedDataPath build/DerivedData -parallelizeTargets \
     -skipPackagePluginValidation -skipMacroValidation -quiet 2>&1 | grep -E ' error:|BUILD'
   ```
   Repeat with `-scheme Authenticator`. Use `build-for-testing`, not `build`: `BitwardenSdkMocks` is reachable only from test targets, and a renamed protocol breaks there first. Outside CI, resolve the destination as `name=$(tr -d '\n' < .test-simulator-device-name),OS=$(tr -d '\n' < .test-simulator-ios-version)`, and avoid `generic/platform=iOS Simulator`, which also builds x86_64 for no extra signal. `./Scripts/bootstrap.sh` must have run first: the `.xcodeproj` files are generated, and a stale one omits sources and reports `cannot find 'X' in scope`, which mimics an SDK break. Note any failure and continue — a clean build rules out compile breaks only.
4. `bash .claude/skills/evaluating-sdk-internal-updates/sdk-surface-diff.sh <sdk-swift-path> <old> <new>` prints RANGE, REMOVED, ADDED and MUTATED. Add `--type <TypeName>` for one type's members, or `--decls` for a line-level diff of the whole surface, which is the only view showing an argument label or return type change on a free function. Comparisons are keyed by symbol name tree-wide rather than per file, since relocation in the flat module otherwise reads as removal. MUTATED covers type declarations only; function names are overloaded, so joining them on name cross-products. ADDED lists `<kind> <name>`, so a field added to one type hides behind an identical field name on another — `--decls` reveals it, and only a pre-existing owner is a break. RANGE is oldest-first, and its `base:` line carries the old sdk-internal SHA that `OLD..NEW` excludes.
5. `git -C <sdk-internal> diff <old-sha>..<new-sha> -- '*/uniffi.toml'`. Only `bitwarden-core` and `bitwarden-crypto` set `generate_codable_conformance`, so a type moving to any other crate silently loses `Codable`, which is a serialization break with no compile signal. Error enums come from `#[bitwarden_error(flat)]` rather than `derive(uniffi::Error)`, so grepping for `uniffi::` misses the entire error surface.
6. For each symbol from steps 4-5, `grep -rn '<Symbol>' --include='*.swift' .` — no module list and no import-prefix filter, since everything arrives via plain `import BitwardenSdk`. Both apps consume the SDK; `AuthenticatorShared` is not optional. A surface change stays a candidate until a call site makes it a finding. A new protocol requirement has no symbol to grep yet, so grep the concept and check the hand-written `with_foreign` conformers: `Fido2CredentialStore`, `ClientManagedTokens`, `ServerCommunicationConfigRepository`, `Fido2UserInterface`.
7. Two gates a green build passes through. `grep -A3 'BitwardenSdk:' project-common.yml`: `SDKVersionInfoTests` asserts the trailing comment against `^\d+\.\d+\.\d+-\d+-[a-f0-9]+$`, and a leading `v` fails it, meaning the bump was dispatched with the tag name instead of the release name. Then `grep -n 'extension ' BitwardenSdkMocks/BitwardenSdkMocks.swift`: Sourcery cannot annotate external-module types, so that hand-maintained list is the only diff evidence of a protocol rename. Add an entry for a new client protocol iOS actually consumes, and never edit the generated mocks.
8. Report compile-time breaks, runtime and serialization considerations, and confirmed-safe, each with commit, symbol and call sites, and state whether the build passed. Cite sdk-internal commits and PRs as `bitwarden/sdk-internal#<N>` or a full URL; a bare `#<N>` copied from a commit subject auto-links into bitwarden/ios and tags an unrelated PR.

## Resolve

9. Fix anything found, compile-time or runtime, whenever the correct behavior is clear and in scope. For a new required method with no existing consumer, stub it: an empty body with a `// no-op` comment, or a `nil`/default return. Never `fatalError()`, `preconditionFailure()`, `try!` or a force-unwrap, which turn a stub into a crash. A sibling's structure is a template; its behavior is not evidence for yours. If unsure, report it instead of guessing, along with anything needing a product decision. Invoke `Skill(implementing-ios-code)` first if the fix is not mechanical, then commit with `Skill(bitwarden-delivery-tools:committing-changes)`.
10. Re-run step 3 on both schemes, then spot-test the test targets of the modules you edited, mapped with the table in `fixing-flaky-tests` step 2:
    ```bash
    xcrun xcodebuild test-without-building -workspace Bitwarden.xcworkspace -scheme Bitwarden \
      -configuration Debug -destination "platform=iOS Simulator,id=$_SIMULATOR_ID" \
      -derivedDataPath build/DerivedData -only-testing:BitwardenSharedTests 2>&1 \
      | grep -E 'Executed|Suite .* (passed|failed)| error:'
    ```
    Filter at target level; the XCTest `Target/Class` form matches no Swift Testing suite. `xcodebuild` exits 0 when a filter matches nothing, so check that `Executed <N> tests` is non-zero. `BitwardenKitTests` and `NetworkingTests` run from the `Bitwarden` scheme.
