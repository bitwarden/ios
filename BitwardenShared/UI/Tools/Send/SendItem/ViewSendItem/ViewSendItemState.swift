import BitwardenSdk
import Foundation

// MARK: - ViewSendItemState

/// An object that defines the current state of a `ViewSendItemView`.
///
struct ViewSendItemState: Equatable {
    // MARK: Properties

    /// The send to show the details of.
    let sendView: SendView

    /// A URL for sharing the send.
    var shareURL: URL?

    /// A toast message to show in the view.
    var toast: Toast?

    // MARK: Computed Properties

    /// The send's share URL without a scheme for displaying in the UI.
    var displayShareURL: String? {
        shareURL?.withoutScheme
    }

    /// The navigation title of the view.
    var navigationTitle: String {
        switch sendView.type {
        case .file: Localizations.viewFileSend
        case .text: Localizations.viewTextSend
        }
    }
}
