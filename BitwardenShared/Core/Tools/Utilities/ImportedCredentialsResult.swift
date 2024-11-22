/// Represents the result of imported credentials of one type.
struct ImportedCredentialsResult: Equatable, Sendable {
    /// The credential type imported.
    let localizedType: String

    /// The number of credentials imported for the type
    let count: Int
}

extension ImportedCredentialsResult: Identifiable {
    public var id: String {
        localizedType
    }
}
