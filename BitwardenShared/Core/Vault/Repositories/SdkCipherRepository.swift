import BitwardenKit
import BitwardenSdk

/// `CipherRepository` implementation to be used on SDK client-managed state.
final class SdkCipherRepository: @unchecked Sendable, BitwardenSdk.CipherRepository {
    /// The service used to manage syncing and updates to the user's ciphers.
    let cipherService: CipherService
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// Initializes a `SdkCipherRepository`.
    /// - Parameters:
    ///   - cipherService: The service used to manage syncing and updates to the user's ciphers.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    init(cipherService: CipherService, errorReporter: ErrorReporter) {
        self.cipherService = cipherService
        self.errorReporter = errorReporter
    }

    func get(id: String) async throws -> BitwardenSdk.Cipher? {
        try await cipherService.fetchCipher(withId: id)
    }

    func has(id: String) async throws -> Bool {
        let cipher = try? await cipherService.fetchCipher(withId: id)
        return cipher != nil
    }

    func list() async throws -> [BitwardenSdk.Cipher] {
        try await cipherService.fetchAllCiphers()
    }

    func remove(id: String) async throws {
        try await cipherService.deleteCipherWithLocalStorage(id: id)
    }

    func set(id: String, value: BitwardenSdk.Cipher) async throws {
        guard id == value.id else {
            errorReporter.log(
                error: BitwardenError.dataError("CipherRepository: Trying to update a cipher with mismatch IDs")
            )
            return
        }
        try await cipherService.updateCipherWithLocalStorage(value)
    }
}
