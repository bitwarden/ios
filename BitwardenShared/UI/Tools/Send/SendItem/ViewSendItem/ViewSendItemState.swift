import BitwardenSdk

// MARK: - ViewSendItemState

/// An object that defines the current state of a `ViewSendItemView`.
///
struct ViewSendItemState: Equatable {
    // MARK: Properties

    /// The send to show the details of.
    let sendView: SendView

    // MARK: Computed Properties

    /// The navigation title of the view.
    var navigationTitle: String {
        switch sendView.type {
        case .file: Localizations.viewFileSend
        case .text: Localizations.viewTextSend
        }
    }
}
