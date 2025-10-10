import BitwardenKit

// MARK: - ViewSendItemAction

/// Actions that can be processed by a `ViewSendItemProcessor`.
///
enum ViewSendItemAction: Equatable {
    /// The copy notes button was tapped.
    case copyNotes

    /// The copy share URL button was tapped.
    case copyShareURL

    /// The dismiss button was tapped.
    case dismiss

    /// The edit item button was tapped.
    case editItem

    /// The share button was tapped.
    case shareSend

    /// The additional options section was toggled.
    case toggleAdditionalOptions

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
