import BitwardenSdk

/// A private key, encrypted with a symmetric key.
typealias WrappedPrivateKey = EncString

/// A public key, signed with the accounts signature key.
typealias SignedPublicKey = String

/// A public key in base64 encoded SPKI-DER.
typealias UnsignedPublicKey = [UInt8]

/// A signature key encrypted with a symmetric key.
typealias WrappedSigningKey = EncString

/// A signature public key (verifying key) in base64 encoded CoseKey format.
typealias VerifyingKey = String
