import BitwardenSdk
import Foundation

// MARK: - AddSendContentType

/// Values describing content that can be used to pre-fill the add send screen.
///
public enum AddSendContentType: Equatable, Hashable {
    /// A file type, with the provided name and data.
    case file(fileName: String, fileData: Data)

    /// A text type, with the provided string value.
    case text(String)

    /// A send type, without pre-filled send content.
    case type(SendType)
}

// MARK: - SendItemRoute

/// The route to a specific screen in the send item flow.
///
public enum SendItemRoute: Equatable, Hashable {
    /// A route to the add item screen.
    ///
    /// - Parameter content: Initial content to pre-fill the add send screen with.
    ///
    case add(content: AddSendContentType?)

    /// A route specifying that the send item flow has been cancelled.
    case cancel

    /// A route specifying that the send item flow has been completed, along with the new/updated
    /// send view.
    ///
    /// - Parameter sendView: The new or updated `SendView`.
    ///
    case complete(_ sendView: SendView)

    /// A route specifying that the send item flow completed by deleting a send.
    case deleted

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
    case edit(_ sendView: SendView)

    /// A route to a file selection route.
    ///
    /// - Parameter route: The file selection route to follow.
    ///
    case fileSelection(_ route: FileSelectionRoute)

    /// A route to the password generator screen.
    case generator

    /// A route to share the provided URL.
    ///
    /// - Parameter url: The `URL` to share.
    ///
    case share(url: URL)

    /// A route to view send item screen.
    ///
    /// - Parameter sendView: The `SendView` to view the details of.
    ///
    case view(_ sendView: SendView)

    /// A route to display the profile switcher.
    ///
    case viewProfileSwitcher
}
