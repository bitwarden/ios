import AuthenticationServices
import BitwardenSdk

@available(iOSApplicationExtension 17.0, *)
extension ASPasskeyCredentialRequest {
    // MARK: Methods

    /// Gets the excluded credentials list from this request.
    /// - Returns: An array of `PublicKeyCredentialDescriptor` for excluded credentials based on this request.
    func excludedCredentialsList() -> [PublicKeyCredentialDescriptor]? {
        guard #available(iOS 18.0, *),
              let excludedCredentials,
              !excludedCredentials.isEmpty else {
            return nil
        }

        return excludedCredentials.map { $0.toPublicKeyCredentialDescriptor() }
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
