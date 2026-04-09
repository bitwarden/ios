import BitwardenKit
@testable import BitwardenShared

class MockTextAutofillHelperDelegate: TextAutofillHelperDelegate {
    var alertsShown = [BitwardenKit.Alert]()
    var alertOnDismissed: (() -> Void)?
    var completeTextRequestText: String?

    func completeTextRequest(text: String) {
        completeTextRequestText = text
    }

    func showAlert(_ alert: BitwardenKit.Alert, onDismissed: (() -> Void)?) {
        alertsShown.append(alert)
        alertOnDismissed = onDismissed
    }
}
