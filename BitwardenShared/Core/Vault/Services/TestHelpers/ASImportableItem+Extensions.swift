#if SUPPORTS_CXP
import AuthenticationServices

@available(iOS 26.0, *)
extension ASImportableItem {
    /// Provides a fixture for `ASImportableItem`.
    static func fixture(
        id: Data = Data(capacity: 16),
        created: Date = .now,
        lastModified: Date = .now,
        title: String = "",
        subtitle: String? = nil,
        favorite: Bool = false,
        scope: ASImportableCredentialScope? = nil,
        credentials: [ASImportableCredential] = [],
        tags: [String] = []
    ) -> ASImportableItem {
        ASImportableItem(
            id: id,
            created: created,
            lastModified: lastModified,
            title: title,
            subtitle: subtitle,
            favorite: favorite,
            scope: scope,
            credentials: credentials,
            tags: tags
        )
    }
}
#endif
