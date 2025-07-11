import BitwardenKit
import BitwardenSdk

// MARK: - CiphersClientWrapperService

/// A protocol wrapping the `CiphersClient` service for extended functionality.
protocol CiphersClientWrapperService {
    /// Decrypts `ciphers` in batch and perform process on each decrypted cipher of the batch.
    /// - Parameters:
    ///   - batchSize: The size of the batch.
    ///   - ciphers: The ciphers to decrypt and process
    ///   - onCipher: The action to perform on each decrypted cipher.
    func decryptAndProcessCiphersInBatch(
        batchSize: Int,
        ciphers: [Cipher],
        onCipher: (CipherListView) async throws -> Void
    ) async
}

extension CiphersClientWrapperService {
    /// Decrypts `ciphers` in batch and perform process on each decrypted cipher of the batch.
    /// Batch size: `Constants.decryptCiphersBatchSize`.
    ///
    /// - Parameters:
    ///   - ciphers: The ciphers to decrypt and process
    ///   - onCipher: The action to perform on each decrypted cipher.
    func decryptAndProcessCiphersInBatch(
        ciphers: [Cipher],
        onCipher: (CipherListView) async throws -> Void
    ) async {
        await decryptAndProcessCiphersInBatch(
            batchSize: Constants.decryptCiphersBatchSize,
            ciphers: ciphers,
            onCipher: onCipher
        )
    }
}

// MARK: - DefaultCiphersClientWrapperService

/// Default implementation of `CiphersClientWrapperService`.
struct DefaultCiphersClientWrapperService: CiphersClientWrapperService {
    // MARK: Properties

    /// The service that handles common client functionality such as encryption and decryption.
    let clientService: ClientService
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    // MARK: Methods

    func decryptAndProcessCiphersInBatch(
        batchSize: Int,
        ciphers: [Cipher],
        onCipher: (CipherListView) async throws -> Void
    ) async {
        for start in stride(from: 0, to: ciphers.count, by: batchSize) {
            let end = min(start + batchSize, ciphers.count)

            do {
                let decryptedCiphers = try await clientService.vault().ciphers().decryptList(
                    ciphers: Array(ciphers[start ..< end])
                )

                for decryptedCipher in decryptedCiphers {
                    try await onCipher(decryptedCipher)
                }
            } catch {
                errorReporter.log(error: error)
            }
        }
    }
}
