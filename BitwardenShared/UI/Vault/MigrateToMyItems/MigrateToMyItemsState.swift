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
    }

    // MARK: Properties

    /// The ID of the organization requesting the item transfer.
    var organizationId: String

    /// The name of the organization requesting the item transfer.
    var organizationName: String = ""

    /// The current page being displayed.
    var page: Page = .transfer
}
