import AuthenticationServices
import BitwardenSdk

extension ASAuthorizationPublicKeyCredentialUserVerificationPreference {
    /// Maps to the Bitwarden Sdk user verification prefernece object
    func toSdkUserVerificationPreference() -> BitwardenSdk.Uv {
        switch self {
        case ASAuthorizationPublicKeyCredentialUserVerificationPreference.discouraged:
            BitwardenSdk.Uv.discouraged
        case ASAuthorizationPublicKeyCredentialUserVerificationPreference.preferred:
            BitwardenSdk.Uv.preferred
        case ASAuthorizationPublicKeyCredentialUserVerificationPreference.required:
            BitwardenSdk.Uv.required
        default:
            BitwardenSdk.Uv.required
        }
    }
}
