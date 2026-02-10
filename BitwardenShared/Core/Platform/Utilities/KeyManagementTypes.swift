// swiftlint:disable:this file_name

import BitwardenSdk

/// A private key, encrypted with a symmetric key.
typealias WrappedPrivateKey = EncString

/// A public key, signed with the accounts signature key.
typealias SignedPublicKey = String

/// A signature key encrypted with a symmetric key.
typealias WrappedSigningKey = EncString

/// A signature public key (verifying key) in base64 encoded CaseKey format.
typealias VerifyingKey = String
