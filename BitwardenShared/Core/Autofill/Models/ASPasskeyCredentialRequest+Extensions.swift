import AuthenticationServices
import BitwardenSdk

@available(iOSApplicationExtension 17.0, *)
extension ASPasskeyCredentialRequest {
    // MARK: Methods

    /// Gets the PRF input of this assertion request for the SDK. The salts stay raw: the SDK applies
    /// the WebAuthn PRF hash.
    /// - Returns: The assertion extension input, or `nil` if the request has no PRF input.
    func assertionPrfExtensionsInput() -> GetAssertionExtensionsInput? {
        guard #available(iOS 18.0, *),
              case let .assertion(assertionInput) = extensionInput,
              let prf = assertionInput.prf
        else {
            return nil
        }
        return GetAssertionExtensionsInput(
            prf: GetAssertionPrfInput(
                eval: prf.inputValues.map(PrfInputValues.init(inputValues:)),
                evalByCredential: prf.perCredentialInputValues?.mapValues(PrfInputValues.init(inputValues:)),
            ),
        )
    }

    /// Gets the excluded credentials list from this request.
    /// - Returns: An array of `PublicKeyCredentialDescriptor` for excluded credentials based on this request.
    func excludedCredentialsList() -> [PublicKeyCredentialDescriptor]? {
        guard #available(iOS 18.0, *),
              let excludedCredentials,
              !excludedCredentials.isEmpty else {
            return nil
        }

        return excludedCredentials.map { PublicKeyCredentialDescriptor(from: $0) }
    }

    /// Gets an array of the `PublicKeyCredentialParameters` based on this request.
    /// - Returns: An array of `PublicKeyCredentialParameters`.
    func getPublicKeyCredentialParams() -> [PublicKeyCredentialParameters] {
        guard !supportedAlgorithms.isEmpty else {
            return [
                PublicKeyCredentialParameters.es256(),
                PublicKeyCredentialParameters.rs256(),
            ]
        }

        guard supportedAlgorithms.contains(where: { alg in
            alg.rawValue == PublicKeyCredentialParameters.es256Algorithm
        }) else {
            return []
        }
        return [PublicKeyCredentialParameters.es256()]
    }
}

// MARK: - PrfInputValues

@available(iOS 18.0, *)
extension PrfInputValues {
    /// Creates the SDK PRF input values from the PRF salts of a passkey request.
    init(inputValues: ASAuthorizationPublicKeyCredentialPRFAssertionInput.InputValues) {
        self.init(first: inputValues.saltInput1, second: inputValues.saltInput2)
    }
}
