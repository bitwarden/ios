import BitwardenKit
import TestHelpers

public class MockBiometricsStateService: BiometricsStateService {
    public var activeAccountIdError: Error?
    public var activeAccountIdResult = Result<String, Error>.failure(BitwardenTestError.mock("Mock error not set"))
    public var biometricAuthenticationEnabledResult: Result<Bool, Error> = .success(false)
    public var setBiometricAuthenticationEnabledError: Error?

    public init() {}

    public func getActiveAccountId() async throws -> String {
        if let activeAccountIdError {
            throw activeAccountIdError
        }
        return try activeAccountIdResult.get()
    }

    public func getBiometricAuthenticationEnabled() async throws -> Bool {
        try biometricAuthenticationEnabledResult.get()
    }

    public func setBiometricAuthenticationEnabled(_ isEnabled: Bool?) async throws {
        if let setBiometricAuthenticationEnabledError {
            throw setBiometricAuthenticationEnabledError
        }
        biometricAuthenticationEnabledResult = .success(isEnabled ?? false)
    }
}
