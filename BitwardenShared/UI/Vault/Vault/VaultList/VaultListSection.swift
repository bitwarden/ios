/// Data model for a section of items in the vault list.
///
public struct VaultListSection: Equatable, Identifiable, Sendable {
    // MARK: Properties

    /// The identifier for the section.
    public let id: String

    /// The list of items in the section.
    public let items: [VaultListItem]

    /// The name of the section, displayed as section header.
    public let name: String
}

// MARK: - [VaultListSection]

extension [VaultListSection] {
    /// Returns whether any login items exist within the vault list sections.
    var hasLoginItems: Bool {
        flatMap(\.items)
            .contains { item in
                if case let .group(group, count) = item.itemType, group == .login {
                    count > 0 // swiftlint:disable:this empty_count
                } else if case let .cipher(cipherView, _) = item.itemType, cipherView.type == .login {
                    true
                } else {
                    false
                }
            }
    }
}
