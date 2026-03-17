import Foundation

// MARK: - MigrateToMyItemsState

/// An object that defines the current state of a `MigrateToMyItemsView`.
///
struct MigrateToMyItemsState: Equatable, Sendable {
    // MARK: Types

    /// An enumeration of the pages in the migrate to my items flow.
    ///
    enum Page: Equatable, Sendable {
        /// The main screen prompting the user to accept or decline the transfer.
        case transfer

        /// The confirmation screen shown when the user chooses to decline.
        case declineConfirmation

        /// The page shown in app extensions prompting the user to complete migration in the main app.
        case extensionPrompt
    }

    // MARK: Properties

    /// Whether the view is being displayed in an app extension context.
    var isExtension: Bool = false

    /// The ID of the organization requesting the item transfer.
    var organizationId: String

    /// The name of the organization requesting the item transfer.
    var organizationName: String = ""

    /// The current page being displayed.
    var page: Page = .transfer
}
