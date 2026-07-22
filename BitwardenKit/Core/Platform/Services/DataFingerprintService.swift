import CryptoKit
import Foundation

// MARK: - DataFingerprintService

/// A service that computes a deterministic integrity fingerprint for arbitrary encodable data,
/// useful for detecting tampering in cached or persisted data.
///
public protocol DataFingerprintService { // sourcery: AutoMockable
    /// Computes a SHA-256 integrity fingerprint for the given data, using a sorted-keys JSON
    /// encoding so the result is deterministic regardless of dictionary iteration order.
    ///
    /// - Parameter data: The data to fingerprint.
    /// - Returns: A lowercase hexadecimal SHA-256 digest of the encoded data.
    ///
    func fingerprint(for data: Encodable) throws -> String
}

// MARK: - DefaultDataFingerprintService

/// The default implementation of `DataFingerprintService`.
///
public struct DefaultDataFingerprintService: DataFingerprintService {
    public init() {}

    public func fingerprint(for data: Encodable) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(data).generatedHash(using: SHA256.self)
    }
}
