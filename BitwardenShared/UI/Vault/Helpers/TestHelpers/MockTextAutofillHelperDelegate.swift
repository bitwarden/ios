@testable import BitwardenShared

class MockTextAutofillHelperDelegate: TextAutofillHelperDelegate {
    var alertsShown = [Alert]()
    var alertOnDismissed: (() -> Void)?
    var completeTextRequestText: String?

    func completeTextRequest(text: String) {
        completeTextRequestText = text
    }

    func showAlert(_ alert: BitwardenShared.Alert, onDismissed: (() -> Void)?) {
        alertsShown.append(alert)
        alertOnDismissed = onDismissed
    }
}
