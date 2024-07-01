import BitwardenSdk

extension PublicKeyCredentialParameters {
    static let es256Algorithm: Int64 = -7
    static let rs256Algorithm: Int64 = -257

    static func es256() -> PublicKeyCredentialParameters {
        PublicKeyCredentialParameters(ty: Constants.defaultFido2PublicKeyCredentialType, alg: es256Algorithm)
    }

    static func rs256() -> PublicKeyCredentialParameters {
        PublicKeyCredentialParameters(ty: Constants.defaultFido2PublicKeyCredentialType, alg: rs256Algorithm)
    }
}
