@testable import BitwardenShared

class MockAppExtensionDelegate: AppExtensionDelegate {
    var authCompletionRoute = AppRoute.vault(.autofillList)
    var didCancelCalled = false
    var didCompleteAutofillRequest: (username: String, password: String)?
    var isInAppExtension = false
    var uri: String?

    func completeAutofillRequest(username: String, password: String) {
        didCompleteAutofillRequest = (username, password)
    }

    func didCancel() {
        didCancelCalled = true
    }
}
