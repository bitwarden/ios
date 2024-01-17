import BitwardenSdk

@testable import BitwardenShared

extension SendListItem {
    static func fixture(
        sendView: SendView = .fixture()
    ) -> SendListItem {
        SendListItem(sendView: sendView)!
    }

    static func groupFixture(
        id: String = "1",
        sendType: BitwardenShared.SendType = .text,
        count: Int = 42
    ) -> SendListItem {
        SendListItem(id: id, itemType: .group(sendType, count))
    }
}
