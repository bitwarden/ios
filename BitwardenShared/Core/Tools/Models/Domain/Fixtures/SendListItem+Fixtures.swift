import BitwardenSdk

@testable import BitwardenShared

extension SendListItem {
    static func fixture(
        sendView: SendView = .fixture()
    ) -> SendListItem {
        SendListItem(sendView: sendView)!
    }
}
