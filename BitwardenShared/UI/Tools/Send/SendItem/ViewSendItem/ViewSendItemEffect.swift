// MARK: - ViewSendItemEffect

/// Effects that can be processed by a `ViewSendItemProcessor`.
///
enum ViewSendItemEffect: Equatable {
    /// The delete send button was tapped.
    case deleteSend

    /// Any initial data for the view should be loaded.
    case loadData

    /// Stream the details of the send.
    case streamSend
}
