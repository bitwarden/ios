/// Data model for a section of items in the item list
///
public struct ItemListSection: Equatable, Identifiable {
    // MARK: Properties

    /// The identifier for the section
    public let id: String

    /// The list of items in the section
    public let items: [ItemListItem]

    /// The name of the section, displayed as a section header
    public let name: String
}
