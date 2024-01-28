// MARK: - SendListSection

/// Data model for a section of items in the send list.
///
public struct SendListSection: Equatable, Identifiable {
    // MARK: Properties

    /// The identifier for the section.
    public let id: String

    /// A flag indicating if the count for this section should be displayed.
    public let isCountDisplayed: Bool

    /// The list of items in the section.
    public let items: [SendListItem]

    /// The name of the section, displayed as section header.
    public let name: String
}
