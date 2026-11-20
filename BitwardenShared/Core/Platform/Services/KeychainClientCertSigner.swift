import BitwardenSdk
import Foundation
import Security

// MARK: - KeychainClientCertSigner

/// A `ClientCertSigner` that signs the SDK's TLS handshake messages with the private key of a
/// Keychain `SecIdentity`. The SDK delegates signing to the app so the private key stays in the
/// Keychain.
///
/// The SDK calls `sign(scheme:message:)` synchronously on the thread awaiting the SDK call, so
/// everything it needs is resolved at initialization.
///
final class KeychainClientCertSigner: ClientCertSigner, @unchecked Sendable {
    // MARK: Private Properties

    /// The identity's private key. `SecKey` is thread-safe, which makes the `@unchecked Sendable`
    /// conformance sound.
    private let privateKey: SecKey

    // MARK: Initialization

    /// Initialize a `KeychainClientCertSigner`.
    ///
    /// - Parameter identity: The identity whose private key signs the handshake.
    /// - Throws: `ClientCertSignerError.Unexpected` if the identity's private key can't be read.
    ///
    convenience init(identity: SecIdentity) throws {
        var key: SecKey?
        let status = SecIdentityCopyPrivateKey(identity, &key)
        guard status == errSecSuccess, let key else {
            throw ClientCertSignerError.Unexpected(
                reason: "Unable to copy the identity's private key (OSStatus \(status))",
            )
        }
        self.init(privateKey: key)
    }

    /// Initialize a `KeychainClientCertSigner`.
    ///
    /// - Parameter privateKey: The private key that signs the handshake.
    ///
    init(privateKey: SecKey) {
        self.privateKey = privateKey
    }

    // MARK: ClientCertSigner

    func schemes() -> [TlsSigScheme] {
        privateKey.tlsSignatureSchemes
    }

    func sign(scheme: TlsSigScheme, message: Data) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            scheme.secKeyAlgorithm,
            message as CFData,
            &error,
        ) else {
            let reason = error.map { $0.takeRetainedValue().localizedDescription } ?? "Unknown error"
            throw ClientCertSignerError.SigningFailed(reason: reason)
        }
        return signature as Data
    }
}

// MARK: - ClientCertificate

extension ClientCertificate {
    /// Creates an SDK client certificate that presents the identity's certificate and signs with
    /// its Keychain private key.
    ///
    /// The Keychain stores only the identity, not the intermediates from the imported PKCS#12, so
    /// the chain holds the leaf certificate alone.
    ///
    /// - Parameter identity: The Keychain identity to authenticate with.
    /// - Throws: `ClientCertSignerError.Unexpected` if the identity's certificate or private key
    ///   can't be read.
    ///
    convenience init(identity: SecIdentity) throws {
        var certificate: SecCertificate?
        let status = SecIdentityCopyCertificate(identity, &certificate)
        guard status == errSecSuccess, let certificate else {
            throw ClientCertSignerError.Unexpected(
                reason: "Unable to copy the identity's certificate (OSStatus \(status))",
            )
        }
        try self.init(
            chain: [SecCertificateCopyData(certificate) as Data],
            signer: KeychainClientCertSigner(identity: identity),
        )
    }
}

// MARK: - SecKey

private extension SecKey {
    /// The TLS signature schemes the private key can sign with.
    var tlsSignatureSchemes: [TlsSigScheme] {
        let attributes = SecKeyCopyAttributes(self) as? [CFString: Any]
        let keyType = attributes?[kSecAttrKeyType] as? String
        let keySize = attributes?[kSecAttrKeySizeInBits] as? Int

        let candidates: [TlsSigScheme] = switch keyType {
        case String(kSecAttrKeyTypeRSA):
            // The SDK drops the RSA schemes the key's modulus is too short for.
            [.rsaPkcs1Sha256, .rsaPkcs1Sha384, .rsaPkcs1Sha512, .rsaPssSha256, .rsaPssSha384, .rsaPssSha512]
        case String(kSecAttrKeyTypeECSECPrimeRandom):
            // Each ECDSA scheme is bound to one curve, so a key matches at most one of them.
            switch keySize {
            case 256: [.ecdsaP256Sha256]
            case 384: [.ecdsaP384Sha384]
            default: []
            }
        default:
            []
        }
        return candidates.filter { SecKeyIsAlgorithmSupported(self, .sign, $0.secKeyAlgorithm) }
    }
}

// MARK: - TlsSigScheme

private extension TlsSigScheme {
    /// The hash-and-sign algorithm for the scheme. The SDK passes the unhashed handshake message,
    /// so these are the `Message` variants rather than the `Digest` ones.
    var secKeyAlgorithm: SecKeyAlgorithm {
        switch self {
        case .rsaPkcs1Sha256: .rsaSignatureMessagePKCS1v15SHA256
        case .rsaPkcs1Sha384: .rsaSignatureMessagePKCS1v15SHA384
        case .rsaPkcs1Sha512: .rsaSignatureMessagePKCS1v15SHA512
        case .rsaPssSha256: .rsaSignatureMessagePSSSHA256
        case .rsaPssSha384: .rsaSignatureMessagePSSSHA384
        case .rsaPssSha512: .rsaSignatureMessagePSSSHA512
        case .ecdsaP256Sha256: .ecdsaSignatureMessageX962SHA256
        case .ecdsaP384Sha384: .ecdsaSignatureMessageX962SHA384
        }
    }
}
