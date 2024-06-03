/// A protocol to manage user verification execution
///
protocol UserVerificationRunner {
    // MARK: Methods

    /// Executes the `verifyFunction` and if needed it's repeated until maximum number of attempts is reached.
    ///
    func verifyWithAttempts(
        verifyFunction: () async throws -> UserVerificationResult
    ) async throws -> UserVerificationResult

    /// Performs the verifications in `verifyFunctions` continuing
    /// if the previous one couldn't perform the verification,
    /// i.e. the result is `UserVerificationResult.cantPerform`
    ///
    func verifyInQueue(
        verifyFunctions: [() async throws -> UserVerificationResult]
    ) async throws -> UserVerificationResult
}

// MARK: - UserVerificationRunner

/// Default implementation of `UserVerificationRunner`
///
class DefaultUserVerificationRunner: UserVerificationRunner {
    func verifyWithAttempts(
        verifyFunction: () async throws -> UserVerificationResult
    ) async throws -> UserVerificationResult {
        var attempts: Int8 = 0
        var result: UserVerificationResult
        repeat {
            attempts += 1
            result = try await verifyFunction()
        } while attempts < Constants.maxUnlockUnsuccessfulAttempts && result == .notVerified

        return result
    }

    func verifyInQueue(
        verifyFunctions: [() async throws -> UserVerificationResult]
    ) async throws -> UserVerificationResult {
        for verifyFunction in verifyFunctions {
            let result = try await verifyFunction()
            if result != .unableToPerform {
                return result
            }
        }

        return .unableToPerform
    }
}
