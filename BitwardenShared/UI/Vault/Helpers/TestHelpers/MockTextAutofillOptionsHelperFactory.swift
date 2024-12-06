import BitwardenSdk

@testable import BitwardenShared

class MockTextAutofillOptionsHelperFactory: TextAutofillOptionsHelperFactory {
    var createResult: TextAutofillOptionsHelper?

    func create(cipherView: CipherView) -> TextAutofillOptionsHelper {
        createResult ?? MockTextAutofillOptionsHelper()
    }
}
