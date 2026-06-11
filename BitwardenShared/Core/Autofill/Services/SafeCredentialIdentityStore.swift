import AuthenticationServices

// MARK: - SafeCredentialIdentityStore

/// A `CredentialIdentityStore` that wraps `ASCredentialIdentityStore` and guards against the
/// system invoking a completion handler more than once.
///
/// Several `ASCredentialIdentityStore` completion-handler APIs can deliver their reply over XPC
/// more than once (observed as a crash on iOS 15–17). The compiler-generated `async` bridge for
/// those APIs resumes its continuation on every callback, and resuming a continuation more than
/// once is a fatal error (`EXC_BREAKPOINT`). This wrapper calls the completion-handler variants
/// directly and resumes the continuation at most once, ignoring any further callbacks.
///
/// Only the completion-handler-based APIs (`removeAllCredentialIdentities()` and
/// `replaceCredentialIdentities(with:)`) can be guarded this way. The iOS 17+ APIs that take
/// `[ASCredentialIdentity]` are `async`-only with no completion-handler variant, so they forward
/// directly to the system's `async` methods.
///
/// - Note: The double-callback bug does not occur on iOS 18+. Once the minimum deployment target
///   reaches iOS 18 (i.e. iOS 17 support is dropped), the `@available` annotation below will start
///   emitting deprecation warnings at the call sites. At that point this entire type can be deleted
///   and the conformance restored to the original one-liner:
///
///   ```swift
///   extension ASCredentialIdentityStore: CredentialIdentityStore {}
///   ```
///
///   Then change any call sites that default to `SafeCredentialIdentityStore()` back to
///   `ASCredentialIdentityStore.shared`.
@available(iOS, deprecated: 18.0, message: "Obsolete on iOS 18+; delete and restore the direct conformance (see note).")
class SafeCredentialIdentityStore: CredentialIdentityStore {
    // MARK: Properties

    /// The underlying system store that operations are forwarded to.
    private let store: ASCredentialIdentityStore

    // MARK: Initialization

    /// Initialize a `SafeCredentialIdentityStore`.
    ///
    /// - Parameter store: The underlying system store. Defaults to `ASCredentialIdentityStore.shared`.
    ///
    init(store: ASCredentialIdentityStore = .shared) {
        self.store = store
    }

    // MARK: Type Methods

    /// Bridges an `ASCredentialIdentityStore` completion-handler API to `async`/`await`, resuming
    /// the continuation at most once even if `operation`'s completion handler is invoked multiple
    /// times.
    ///
    /// This is the safeguard against the iOS 15–17 crash where the system invokes a credential
    /// identity store completion handler more than once, double-resuming the continuation. Any
    /// callback after the first is ignored.
    ///
    /// - Parameter operation: Performs the store operation, invoking the supplied completion handler
    ///     when it finishes. The completion handler may be safely called more than once; only the
    ///     first invocation resumes the continuation, with the first reported error (if any).
    ///
    static func withSingleResumedContinuation(
        _ operation: (@escaping @Sendable (Bool, Error?) -> Void) -> Void,
    ) async throws {
        let resumeGuard = SingleResumeGuard()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation { _, error in
                guard resumeGuard.claimResume() else { return }
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    // MARK: Methods

    func removeAllCredentialIdentities() async throws {
        try await Self.withSingleResumedContinuation { completion in
            store.removeAllCredentialIdentities(completion)
        }
    }

    @available(iOS 17.0, *)
    func removeCredentialIdentities(_ credentialIdentities: [any ASCredentialIdentity]) async throws {
        try await store.removeCredentialIdentities(credentialIdentities)
    }

    @available(iOS 17, *)
    func replaceCredentialIdentities(_ newCredentialIdentities: [ASCredentialIdentity]) async throws {
        try await store.replaceCredentialIdentities(newCredentialIdentities)
    }

    func replaceCredentialIdentities(with newCredentialIdentities: [ASPasswordCredentialIdentity]) async throws {
        try await Self.withSingleResumedContinuation { completion in
            store.replaceCredentialIdentities(with: newCredentialIdentities, completion: completion)
        }
    }

    @available(iOS 17.0, *)
    func saveCredentialIdentities(_ credentialIdentities: [any ASCredentialIdentity]) async throws {
        try await store.saveCredentialIdentities(credentialIdentities)
    }

    func state() async -> ASCredentialIdentityStoreState {
        await store.state()
    }
}

// MARK: - SingleResumeGuard

/// A thread-safe, one-shot flag used to ensure a continuation is resumed at most once when a
/// completion handler may be invoked multiple times from concurrent threads.
private final class SingleResumeGuard: @unchecked Sendable {
    /// Whether the continuation has already been resumed.
    private var hasResumed = false

    /// Lock protecting `hasResumed` from concurrent completion-handler invocations.
    private let lock = NSLock()

    /// Atomically claims the right to resume the continuation.
    ///
    /// - Returns: `true` the first time it is called, `false` for every subsequent call.
    ///
    func claimResume() -> Bool {
        lock.withLock {
            guard !hasResumed else { return false }
            hasResumed = true
            return true
        }
    }
}
