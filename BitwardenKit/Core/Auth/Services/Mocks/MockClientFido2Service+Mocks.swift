import BitwardenSdkMocks

public extension MockClientFido2Service {
    /// The `MockClientFido2AuthenticatorProtocol` wired to `vaultAuthenticatorReturnValue`.
    var mockAuthenticator: MockClientFido2AuthenticatorProtocol {
        guard let mock = vaultAuthenticatorReturnValue as? MockClientFido2AuthenticatorProtocol else {
            preconditionFailure(
                "vaultAuthenticatorReturnValue is not a MockClientFido2AuthenticatorProtocol. "
                    + "Use MockClientFido2Service.withMocks() to ensure it is wired correctly.",
            )
        }
        return mock
    }

    /// Creates a `MockClientFido2Service` with nested mocks pre-wired as return values.
    ///
    /// - Parameters:
    ///   - authenticator: The mock to return from `vaultAuthenticator(userInterface:credentialStore:)`.
    ///     Defaults to a new `MockClientFido2AuthenticatorProtocol`.
    ///
    static func withMocks(
        authenticator: MockClientFido2AuthenticatorProtocol = MockClientFido2AuthenticatorProtocol(),
    ) -> MockClientFido2Service {
        let mock = MockClientFido2Service()
        authenticator.credentialsForAutofillReturnValue = []
        mock.vaultAuthenticatorReturnValue = authenticator
        return mock
    }
}
