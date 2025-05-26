import BitwardenSdk

@testable import BitwardenShared

class MockTextAutofillHelper: TextAutofillHelper {
    var handleCipherForAutofillError: Error?
    var handleCipherForAutofillCalledWithCipher: CipherListView?
    var textAutofillHelperDelegate: (any TextAutofillHelperDelegate)?

    func handleCipherForAutofill(cipherListView: CipherListView) async throws {
        handleCipherForAutofillCalledWithCipher = cipherListView
        if let handleCipherForAutofillError {
            throw handleCipherForAutofillError
        }
    }

    func setTextAutofillHelperDelegate(_ delegate: TextAutofillHelperDelegate) {
        textAutofillHelperDelegate = delegate
    }
}
