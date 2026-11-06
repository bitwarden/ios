import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared

// MARK: - SafeCredentialIdentityStoreTests

struct SafeCredentialIdentityStoreTests {
    // MARK: Tests

    /// `withSingleResumedContinuation(_:)` resumes normally when the completion handler is invoked
    /// exactly once with a success result.
    @Test
    func withSingleResumedContinuation_singleSuccess_resumes() async throws {
        try await SafeCredentialIdentityStore.withSingleResumedContinuation { completion in
            completion(true, nil)
        }
    }

    /// `withSingleResumedContinuation(_:)` resumes exactly once and does not crash when the
    /// completion handler is invoked multiple times. This is the regression guard for the iOS 15–17
    /// `ASCredentialIdentityStore` crash where the system delivers its reply more than once,
    /// double-resuming the continuation.
    @Test
    func withSingleResumedContinuation_multipleSuccessCallbacks_resumesOnce() async throws {
        try await SafeCredentialIdentityStore.withSingleResumedContinuation { completion in
            completion(true, nil)
            completion(true, nil)
            completion(false, nil)
        }
    }

    /// `withSingleResumedContinuation(_:)` does not crash when the completion handler is invoked
    /// concurrently from multiple threads, resuming the continuation only once.
    @Test
    func withSingleResumedContinuation_concurrentCallbacks_resumesOnce() async throws {
        try await SafeCredentialIdentityStore.withSingleResumedContinuation { completion in
            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                completion(true, nil)
            }
        }
    }

    /// `withSingleResumedContinuation(_:)` propagates the error when the completion handler is
    /// invoked with one.
    @Test
    func withSingleResumedContinuation_failure_throws() async {
        await #expect(throws: BitwardenTestError.example) {
            try await SafeCredentialIdentityStore.withSingleResumedContinuation { completion in
                completion(false, BitwardenTestError.example)
            }
        }
    }

    /// `withSingleResumedContinuation(_:)` propagates the first reported error and ignores any
    /// subsequent callbacks, including a later success callback.
    @Test
    func withSingleResumedContinuation_errorThenSuccess_throwsFirstError() async {
        await #expect(throws: BitwardenTestError.example) {
            try await SafeCredentialIdentityStore.withSingleResumedContinuation { completion in
                completion(false, BitwardenTestError.example)
                completion(true, nil)
            }
        }
    }
}
