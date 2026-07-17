import BitwardenKit
import CryptoKit
import Foundation

// MARK: - FillAssistFingerprintService

/// A service that computes a deterministic integrity fingerprint for encodable data, used to
/// detect tampering in cached fill-assist rules.
///
protocol FillAssistFingerprintService { // sourcery: AutoMockable
    /// Computes a SHA-256 integrity fingerprint for the given data, using a sorted-keys JSON
    /// encoding so the result is deterministic regardless of dictionary iteration order.
    ///
    /// - Parameter data: The data to fingerprint.
    /// - Returns: A lowercase hexadecimal SHA-256 digest of the encoded data.
    ///
    func fingerprint(for data: Encodable) throws -> String
}

// MARK: - DefaultFillAssistFingerprintService

/// The default implementation of `FillAssistFingerprintService`.
///
struct DefaultFillAssistFingerprintService: FillAssistFingerprintService {
    func fingerprint(for data: Encodable) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(data).generatedHash(using: SHA256.self)
    }
}
