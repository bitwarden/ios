import BitwardenSdk

@testable import BitwardenShared

class MockTextAutofillHelper: TextAutofillHelper {
    var handleCipherForAutofillCalledWithCipher: CipherView?
    var textAutofillHelperDelegate: (any TextAutofillHelperDelegate)?

    func handleCipherForAutofill(cipherView: CipherView) async {
        handleCipherForAutofillCalledWithCipher = cipherView
    }

    func setTextAutofillHelperDelegate(_ delegate: TextAutofillHelperDelegate) {
        textAutofillHelperDelegate = delegate
    }
}
