import BitwardenKit
import CryptoKit
import Foundation

// MARK: - FillAssistCachedData

/// Per-account cached fill-assist rules persisted to `AppSettingsStore`.
///
struct FillAssistCachedData: Codable, Equatable {
    /// The content identifier from the manifest entry at the time of caching (e.g. `"sha256:<hex>"`).
    let cid: String

    /// The fill-assist rules keyed by hostname.
    let rules: [String: FillAssistHostRules]

    /// The fill-assist base URL at the time of caching.
    let sourceUrl: String
}

// MARK: - FillAssistCachedData Fingerprint

extension FillAssistCachedData {
    /// The JSON encoder used to compute the integrity fingerprint. Sorted keys ensure the
    /// encoded bytes are deterministic regardless of dictionary iteration order.
    private static let fingerprintEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    /// Computes a SHA-256 integrity fingerprint for this cached data, using a sorted-keys
    /// JSON encoding so the result is deterministic regardless of dictionary iteration order.
    ///
    /// - Returns: A lowercase hexadecimal SHA-256 digest of the encoded data.
    ///
    func integrityFingerprint() throws -> String {
        try Self.fingerprintEncoder.encode(self).generatedHash(using: SHA256.self)
    }
}

// MARK: - FillAssistHostRules

/// Parsed fill-assist field rules for a single host, pooled across all pathname entries.
///
struct FillAssistHostRules: Codable, Equatable {
    /// CSS-selector-derived HTML attributes grouped by field key (e.g. `"username"`, `"password"`).
    let fields: [String: [FillAssistFieldAttributes]]
}

// MARK: - FillAssistFieldAttributes

/// HTML element attributes extracted from a single CSS selector, used to locate form fields.
/// Shadow DOM selectors and class-only selectors are excluded before this type is produced.
///
struct FillAssistFieldAttributes: Codable, Equatable {
    /// The element's `id` attribute value.
    let id: String?

    /// The element's `name` attribute value.
    let name: String?

    /// The element's `role` attribute value.
    let role: String?

    /// The element's HTML tag name (e.g. `"input"`, `"textarea"`).
    let tagName: String?

    /// The element's `type` attribute value (e.g. `"password"`, `"email"`).
    let type: String?
}
