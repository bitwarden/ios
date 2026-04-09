import BitwardenKit

/// An enum describing the type of secure note.
///
enum SecureNoteType: Int, Codable {
    /// A generic note.
    case generic = 0
}

// MARK: - DefaultValueProvider

extension SecureNoteType: DefaultValueProvider {
    static var defaultValue: SecureNoteType { .generic }
}
