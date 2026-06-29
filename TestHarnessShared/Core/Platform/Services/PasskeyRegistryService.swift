import AuthenticationServices
import Foundation

// MARK: - PasskeyEntry

/// Metadata for a passkey registered via the Test Harness.
///
struct PasskeyEntry: Codable, Equatable, Identifiable {
    var id: UUID
    var rpId: String
    var userName: String
    var displayName: String
    var createdAt: Date
}

// MARK: - PasskeyRegistryService

/// A service that tracks passkeys registered through the Test Harness.
///
protocol PasskeyRegistryService {
    /// Saves a new passkey entry to the registry.
    func savePasskey(_ entry: PasskeyEntry) async

    /// Returns all passkey entries stored in the registry.
    func loadPasskeys() async -> [PasskeyEntry]

    /// Removes the specified entry from the registry.
    func deletePasskey(_ entry: PasskeyEntry) async

    /// Removes all entries from the registry.
    func clearAll() async
}

// MARK: - HasPasskeyRegistryService

protocol HasPasskeyRegistryService {
    var passkeyRegistryService: PasskeyRegistryService { get }
}

// MARK: - DefaultPasskeyRegistryService

/// Passkey registry backed by `ASCredentialIdentityStore` (iOS 17.4+).
///
/// Each entry is stored as an `ASPasskeyCredentialIdentity`. Supplemental metadata
/// (displayName, createdAt) that has no corresponding field on the system type is
/// JSON-encoded and stored in the identity's `recordIdentifier` field.
///
@available(iOS 17.4, *)
class DefaultPasskeyRegistryService: PasskeyRegistryService {
    // MARK: Private Types

    /// Metadata stored in the identity's `recordIdentifier` field.
    private struct EntryMetadata: Codable {
        let createdAt: Date
        let displayName: String
        let id: UUID
    }

    // MARK: Private Properties

    private let decoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        return jsonDecoder
    }()

    private let encoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        return jsonEncoder
    }()

    private let store = ASCredentialIdentityStore.shared

    // MARK: PasskeyRegistryService

    func savePasskey(_ entry: PasskeyEntry) async {
        guard let identity = makeIdentity(for: entry) else { return }
        try? await store.saveCredentialIdentities([identity])
    }

    func loadPasskeys() async -> [PasskeyEntry] {
        await store.credentialIdentities()
            .compactMap { identity -> PasskeyEntry? in
                guard let passkey = identity as? ASPasskeyCredentialIdentity else { return nil }
                return passkeyEntry(from: passkey)
            }
    }

    func deletePasskey(_ entry: PasskeyEntry) async {
        guard let identity = makeIdentity(for: entry) else { return }
        try? await store.removeCredentialIdentities([identity])
    }

    func clearAll() async {
        let all = await store.credentialIdentities()
        guard !all.isEmpty else { return }
        try? await store.removeCredentialIdentities(all)
    }

    // MARK: Private

    private func credentialID(for entry: PasskeyEntry) -> Data {
        Data(entry.id.uuidString.utf8)
    }

    private func makeIdentity(for entry: PasskeyEntry) -> ASPasskeyCredentialIdentity? {
        let idData = credentialID(for: entry)
        let metadata = EntryMetadata(
            createdAt: entry.createdAt,
            displayName: entry.displayName,
            id: entry.id,
        )
        let recordIdentifier = (try? encoder.encode(metadata)).flatMap { String(data: $0, encoding: .utf8) }
        return ASPasskeyCredentialIdentity(
            relyingPartyIdentifier: entry.rpId,
            userName: entry.userName,
            credentialID: idData,
            userHandle: idData,
            recordIdentifier: recordIdentifier,
        )
    }

    private func passkeyEntry(from identity: ASPasskeyCredentialIdentity) -> PasskeyEntry? {
        guard
            let recordIdentifier = identity.recordIdentifier,
            let data = recordIdentifier.data(using: .utf8),
            let metadata = try? decoder.decode(EntryMetadata.self, from: data)
        else { return nil }
        return PasskeyEntry(
            id: metadata.id,
            rpId: identity.relyingPartyIdentifier,
            userName: identity.userName,
            displayName: metadata.displayName,
            createdAt: metadata.createdAt,
        )
    }
}
