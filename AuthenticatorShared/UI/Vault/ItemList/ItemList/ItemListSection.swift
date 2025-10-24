import BitwardenKit

/// Data model for a section of items in the item list.
///
public struct ItemListSection: Equatable, Identifiable {
    // MARK: Properties

    /// The identifier for the section.
    public let id: String

    /// The list of items in the section.
    public let items: [ItemListItem]

    /// The name of the section, displayed as a section header.
    public let name: String
}

/// The section of items in the item list.
///
extension ItemListSection: TOTPUpdatableSection {
    // MARK: Types

    /// The type of item in the list section.
    public typealias Item = ItemListItem

    // MARK: Methods

    /// Update the array of sections with a batch of refreshed items.
    ///
    /// - Parameters:
    ///   - items: An array of updated items that should replace matching items in the current sections.
    ///   - sections: The array of sections to update.
    /// - Returns: A new array of sections with the updated items applied.
    public static func updated(with items: [ItemListItem], from sections: [ItemListSection]) -> [ItemListSection] {
        sections.updated(with: items)
    }
}
