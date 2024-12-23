@testable import BitwardenShared

class MockTwoFactorNoticeHelper: TwoFactorNoticeHelper {
    var maybeShowTwoFactorNoticeCalled = false

    func maybeShowTwoFactorNotice() async {
        maybeShowTwoFactorNoticeCalled = true
    }
}
