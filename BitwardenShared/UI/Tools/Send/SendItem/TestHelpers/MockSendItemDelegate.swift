import BitwardenSdk

@testable import BitwardenShared

// MARK: - MockSendItemDelegate

class MockSendItemDelegate: SendItemDelegate {
    var didSendItemCancelled = false

    var didSendItemCompleted = false
    var sendItemCompletedSendView: SendView?

    var didSendItemDeleted = false

    func sendItemCancelled() {
        didSendItemCancelled = true
    }

    func sendItemCompleted(with sendView: SendView) {
        didSendItemCompleted = true
        sendItemCompletedSendView = sendView
    }

    func sendItemDeleted() {
        didSendItemDeleted = true
    }
}
