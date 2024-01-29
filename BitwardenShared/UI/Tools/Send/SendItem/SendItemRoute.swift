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
}

// MARK: - SendItemRoute

/// The route to a specific screen in the send item flow.
///
public enum SendItemRoute: Equatable, Hashable {
    /// A route to the add item screen.
    ///
    /// - Parameters:
    ///   - content: Initial content to pre-fill the add send screen with.
    ///   - hasPremium: A flag indicating if the active account has premium access.
    ///
    case add(content: AddSendContentType?, hasPremium: Bool)

    /// A route specifing that the send item flow has been cancelled.
    case cancel

    /// A route specifing that the send item flow has been completed, along with the new/updated
    /// send view.
    ///
    /// - Parameter sendView: The new or updated `SendView`.
    ///
    case complete(_ sendView: SendView)

    /// A route specifing that the send item flow completed by deleting a send.
    case deleted

    /// A route to the edit item screen for the provided send.
    ///
    /// - Parameters:
    ///   - sendView: The `SendView` to edit.
    ///   - hasPremium: A flag indicating if the active account has premium access.
    ///
    case edit(_ sendView: SendView, hasPremium: Bool)

    /// A route to a file selection route.
    ///
    /// - Parameter route: The file selection route to follow.
    ///
    case fileSelection(_ route: FileSelectionRoute)

    /// A route to share the provided URL.
    ///
    /// - Parameter url: The `URL` to share.
    ///
    case share(url: URL)
}
