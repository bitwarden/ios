/// Data model for a section of items in the vault list.
///
struct VaultListSection: Equatable, Identifiable {
    // MARK: Properties

    /// The identifier for the section.
    let id: String

    /// The list of items in the section.
    let items: [VaultListItem]

    /// The name of the section, displayed as section header.
    let name: String
}
