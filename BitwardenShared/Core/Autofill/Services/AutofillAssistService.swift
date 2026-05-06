import Foundation

// MARK: - AutofillAssistService

// sourcery: AutoMockable
/// A service for managing URL-based autofill assist mappings.
///
protocol AutofillAssistService {
    /// Returns the saved mapping for the given URL host, or `nil` if none exists.
    ///
    /// - Parameters:
    ///   - host: The URL host to look up.
    ///   - userId: The user ID associated with the mappings.
    /// - Returns: The saved mapping for the host, if any.
    ///
    func getMapping(forHost host: String, userId: String) async throws -> AutofillAssistMapping?

    /// Saves (upserts) a mapping for its URL host.
    ///
    /// - Parameters:
    ///   - mapping: The mapping to save.
    ///   - userId: The user ID associated with the mappings.
    ///
    func saveMapping(_ mapping: AutofillAssistMapping, userId: String) async throws

    /// Returns all saved mappings for the given user.
    ///
    /// - Parameter userId: The user ID associated with the mappings.
    /// - Returns: All saved mappings for the user.
    ///
    func getAllMappings(userId: String) async throws -> [AutofillAssistMapping]

    /// Removes all saved mappings for the given user.
    ///
    /// - Parameter userId: The user ID associated with the mappings.
    ///
    func deleteAllMappings(userId: String) async throws

    /// Resolves the stored stable field identifiers to current `opId` values by scanning page fields.
    ///
    /// - Parameters:
    ///   - mapping: The stored mapping containing stable identifiers.
    ///   - fields: The current page fields to search through.
    /// - Returns: A tuple of resolved opIds for username and password fields.
    ///
    func resolveOpIds(
        mapping: AutofillAssistMapping,
        fields: [PageDetails.Field],
    ) -> (usernameOpId: String?, passwordOpId: String?)
}

// MARK: - HasAutofillAssistService

/// Protocol for a dependency on `AutofillAssistService`.
///
protocol HasAutofillAssistService {
    /// The service for managing URL-based autofill assist mappings.
    var autofillAssistService: AutofillAssistService { get }
}

// MARK: - DefaultAutofillAssistService

/// Default implementation of `AutofillAssistService`.
///
class DefaultAutofillAssistService: AutofillAssistService {
    // MARK: Private Properties

    private let appSettingsStore: AppSettingsStore

    // MARK: Initialization

    /// Creates a new `DefaultAutofillAssistService`.
    ///
    /// - Parameter appSettingsStore: The store used to persist autofill assist mappings.
    ///
    init(appSettingsStore: AppSettingsStore) {
        self.appSettingsStore = appSettingsStore
    }

    // MARK: AutofillAssistService

    func getMapping(forHost host: String, userId: String) async throws -> AutofillAssistMapping? {
        appSettingsStore
            .autofillAssistMappings(userId: userId)
            .first { $0.urlHost == host }
    }

    func saveMapping(_ mapping: AutofillAssistMapping, userId: String) async throws {
        var mappings = appSettingsStore.autofillAssistMappings(userId: userId)
        mappings.removeAll { $0.urlHost == mapping.urlHost }
        mappings.append(mapping)
        appSettingsStore.setAutofillAssistMappings(mappings, userId: userId)
    }

    func getAllMappings(userId: String) async throws -> [AutofillAssistMapping] {
        appSettingsStore.autofillAssistMappings(userId: userId)
    }

    func deleteAllMappings(userId: String) async throws {
        appSettingsStore.setAutofillAssistMappings([], userId: userId)
    }

    func resolveOpIds(
        mapping: AutofillAssistMapping,
        fields: [PageDetails.Field],
    ) -> (usernameOpId: String?, passwordOpId: String?) {
        let findOpId: (String) -> String? = { identifier in
            // Direct opId match — used for fields without stable DOM attributes (same-session).
            if let exact = fields.first(where: { $0.opId == identifier }) {
                return exact.opId
            }
            // Stable attribute-based lookup (htmlId > htmlName > labelTag > placeholder).
            let id = identifier.lowercased()
            return fields.first { field in
                field.htmlId?.lowercased() == id
                    || field.htmlName?.lowercased() == id
                    || field.labelTag?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == id
                    || field.placeholder?.lowercased() == id
            }?.opId
        }
        return (
            usernameOpId: mapping.usernameFieldIdentifier.flatMap(findOpId),
            passwordOpId: mapping.passwordFieldIdentifier.flatMap(findOpId),
        )
    }
}
