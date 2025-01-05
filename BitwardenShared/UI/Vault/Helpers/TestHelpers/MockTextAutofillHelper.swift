import BitwardenSdk

@testable import BitwardenShared

class MockTextAutofillHelper: TextAutofillHelper {
    var handleCipherForAutofillError: Error?
    var handleCipherForAutofillCalledWithCipher: CipherView?
    var textAutofillHelperDelegate: (any TextAutofillHelperDelegate)?

    func handleCipherForAutofill(cipherView: CipherView) async throws {
        handleCipherForAutofillCalledWithCipher = cipherView
        if let handleCipherForAutofillError {
            throw handleCipherForAutofillError
        }
    }

    func setTextAutofillHelperDelegate(_ delegate: TextAutofillHelperDelegate) {
        textAutofillHelperDelegate = delegate
    }
}
