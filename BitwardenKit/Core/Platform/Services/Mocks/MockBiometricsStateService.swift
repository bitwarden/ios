import BitwardenKit
import TestHelpers

public class MockBiometricsStateService: BiometricsStateService {
    // swiftlint:disable identifier_name

    public var activeAccountIdError: Error?
    public var activeAccountIdResult = Result<String, Error>.failure(BitwardenTestError.mock("Mock error not set"))

    public var getBiometricAuthenticationEnabledActiveAccount: Bool = false
    public var getBiometricAuthenticationEnabledByUserId = [String: Bool]()
    public var getBiometricAuthenticationEnabledError: Error?

    public var setBiometricAuthenticationEnabledActiveAccount: Bool?
    public var setBiometricAuthenticationEnabledByUserId = [String: Bool]()
    public var setBiometricAuthenticationEnabledError: Error?

    // swiftlint:enable identifier_name

    public init() {}

    public func getActiveAccountId() async throws -> String {
        if let activeAccountIdError {
            throw activeAccountIdError
        }
        return try activeAccountIdResult.get()
    }

    public func getBiometricAuthenticationEnabled(userId: String?) async throws -> Bool {
        if let getBiometricAuthenticationEnabledError {
            throw getBiometricAuthenticationEnabledError
        }
        guard let userId else {
            return getBiometricAuthenticationEnabledActiveAccount
        }
        guard let value = getBiometricAuthenticationEnabledByUserId[userId] else {
            throw BitwardenTestError.mock("Mock error not user for userId \(userId)")
        }
        return value
    }

    public func setBiometricAuthenticationEnabled(_ isEnabled: Bool?, userId: String?) async throws {
        if let setBiometricAuthenticationEnabledError {
            throw setBiometricAuthenticationEnabledError
        }
        guard let userId else {
            setBiometricAuthenticationEnabledActiveAccount = isEnabled
            return
        }
        setBiometricAuthenticationEnabledByUserId[userId] = isEnabled
    }
}
