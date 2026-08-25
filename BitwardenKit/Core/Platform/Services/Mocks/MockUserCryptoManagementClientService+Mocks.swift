import BitwardenSdkMocks

public extension MockUserCryptoManagementClientService {
    /// The `MockPinSettingsClientProtocol` wired to `pinSettingsReturnValue`.
    var mockPinSettings: MockPinSettingsClientProtocol {
        guard let mock = pinSettingsReturnValue as? MockPinSettingsClientProtocol else {
            preconditionFailure(
                "pinSettingsReturnValue is not a MockPinSettingsClientProtocol. "
                    + "Use MockUserCryptoManagementClientService.withMocks() to ensure it is wired correctly.",
            )
        }
        return mock
    }

    /// Creates a `MockUserCryptoManagementClientService` with nested mocks pre-wired as return values.
    ///
    /// - Parameter pinSettings: The mock to return from `pinSettings()`. Defaults to a new
    ///   `MockPinSettingsClientProtocol`.
    ///
    static func withMocks(
        pinSettings: MockPinSettingsClientProtocol = MockPinSettingsClientProtocol(),
    ) -> MockUserCryptoManagementClientService {
        let mock = MockUserCryptoManagementClientService()
        mock.pinSettingsReturnValue = pinSettings
        return mock
    }
}
