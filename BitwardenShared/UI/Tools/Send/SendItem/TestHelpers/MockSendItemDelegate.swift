import BitwardenSdk

@testable import BitwardenShared

// MARK: - MockSendItemDelegate

class MockSendItemDelegate: SendItemDelegate {
    var didSendItemCancelled = false

    var didSendItemCompleted = false
    var sendItemCompletedSendView: SendView?

    func sendItemCancelled() {
        didSendItemCancelled = true
    }

    func sendItemCompleted(with sendView: SendView) {
        didSendItemCompleted = true
        sendItemCompletedSendView = sendView
    }
}
