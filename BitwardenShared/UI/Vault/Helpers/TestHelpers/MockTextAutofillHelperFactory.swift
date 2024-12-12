import BitwardenSdk

@testable import BitwardenShared

class MockTextAutofillHelperFactory: TextAutofillHelperFactory {
    var createResult: TextAutofillHelper?

    func create(delegate: TextAutofillHelperDelegate) -> TextAutofillHelper {
        createResult ?? NoOpTextAutofillHelper()
    }
}
