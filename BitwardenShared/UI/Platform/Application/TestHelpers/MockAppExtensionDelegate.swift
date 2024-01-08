@testable import BitwardenShared

class MockAppExtensionDelegate: AppExtensionDelegate {
    var didCancelCalled = false
    var isInAppExtension = false

    func didCancel() {
        didCancelCalled = true
    }
}
