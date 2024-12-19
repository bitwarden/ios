import BitwardenSdk

@testable import BitwardenShared

class MockTextAutofillOptionsHelper: TextAutofillOptionsHelper {
    var getTextAutofillOptionsResult: [(localizedOption: String, textToInsert: String)] = []

    func getTextAutofillOptions(cipherView: CipherView) async -> [(localizedOption: String, textToInsert: String)] {
        getTextAutofillOptionsResult
    }
}
