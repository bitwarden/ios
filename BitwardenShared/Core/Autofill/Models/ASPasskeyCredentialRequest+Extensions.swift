import AuthenticationServices
import BitwardenSdk

@available(iOSApplicationExtension 17.0, *)
extension ASPasskeyCredentialRequest {
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
