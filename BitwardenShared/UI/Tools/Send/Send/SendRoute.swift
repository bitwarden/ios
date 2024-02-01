import BitwardenSdk
import Foundation

// MARK: SendRoute

/// The route to a specific screen in the send tab.
///
public enum SendRoute: Equatable {
    /// A route to the add item screen.
    case addItem(type: SendType? = nil)

    /// A route that dismisses a presented sheet.
    ///
    /// - Parameter action: An optional `DismissAction` that is executed after the sheet has been
    ///   dismissed.
    ///
    case dismiss(_ action: DismissAction? = nil)

    /// A route to the edit item screen for the provided send.
    ///
    /// - Parameter sendView: The `SendView` to edit.
    ///
    case editItem(_ sendView: SendView)

    /// A route to the send group screen.
    case group(_ type: SendType)

    /// A route to the send screen.
    case list

    /// A route to share the provided URL.
    ///
    /// - Parameter url: The `URL` to share.
    ///
    case share(url: URL)
}
