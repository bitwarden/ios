@testable import BitwardenShared

class MockAppExtensionDelegate: AppExtensionDelegate {
    var authCompletionRoute: AppRoute? = .vault(.autofillList)
    var canAutofill = true
    var didCancelCalled = false
    var didCompleteAuthCalled = false
    var didCompleteAutofillRequestFields: [(String, String)]?
    var didCompleteAutofillRequestPassword: String?
    var didCompleteAutofillRequestUsername: String?
    var isInAppExtension = false
    var isInAppExtensionSaveLoginFlow = false
    var uri: String?

    func completeAutofillRequest(username: String, password: String, fields: [(String, String)]?) {
        didCompleteAutofillRequestFields = fields
        didCompleteAutofillRequestUsername = username
        didCompleteAutofillRequestPassword = password
    }

    func didCancel() {
        didCancelCalled = true
    }

    func didCompleteAuth() {
        didCompleteAuthCalled = true
    }
}
