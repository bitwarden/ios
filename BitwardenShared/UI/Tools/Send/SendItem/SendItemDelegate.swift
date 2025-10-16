import BitwardenSdk
import Foundation

// MARK: - SendItemDelegate

/// A delegate object that responds to send item events.
///
@MainActor
public protocol SendItemDelegate: AnyObject {
    /// Handle an auth action.
    ///
    /// - Parameter authAction: The AuthAction for the delegate to handle.
    ///
    func handle(_ authAction: AuthAction) async

    /// The send item flow was cancelled.
    func sendItemCancelled()

    /// The send item flow was completed.
    ///
    /// - Parameter sendView: The send view that was added or updated in this flow.
    ///
    func sendItemCompleted(with sendView: SendView)

    /// The send item flow was completed by deleting the send in the flow.
    func sendItemDeleted()
}

/// A delegate object that responds to send item events.
///
@MainActor
public protocol ShareExtensionDelegate: AnyObject {
    /// Handle an auth action
    ///
    func handle(
        _ coordinator: AnyCoordinator<SendRoute, AuthEvent>,
        authAction: AuthAction,
    ) async
}
