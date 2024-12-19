import AuthenticationServices

@available(iOS 18.2, *)
extension ASImportableItem {
    /// Provides a fixture for `ASImportableItem`.
    static func fixture(
        id: Data = Data(capacity: 16),
        created: Date = .now,
        lastModified: Date = .now,
        type: ASImportableItem.ItemType = .login,
        title: String = "",
        subtitle: String? = nil,
        credentials: [ASImportableCredential] = [],
        tags: [String] = []
    ) -> ASImportableItem {
        ASImportableItem(
            id: id,
            created: created,
            lastModified: lastModified,
            type: type,
            title: title,
            subtitle: subtitle,
            credentials: credentials,
            tags: tags
        )
    }
}
