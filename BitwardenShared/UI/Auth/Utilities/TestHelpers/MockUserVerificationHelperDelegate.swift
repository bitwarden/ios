import Foundation
import XCTest

@testable import BitwardenShared

class MockUserVerificationHelperDelegate: UserVerificationDelegate {
    var alertShown = [Alert]()
    var alertShownHandler: ((Alert) async throws -> Void)?
    var alertOnDismissed: (() -> Void)?

    func showAlert(_ alert: Alert) {
        alertShown.append(alert)
        Task {
            do {
                try await alertShownHandler?(alert)
            } catch {
                XCTFail("Error calling alert shown handler: \(error)")
            }
        }
    }

    func showAlert(_ alert: BitwardenShared.Alert, onDismissed: (() -> Void)?) {
        showAlert(alert)
        alertOnDismissed = onDismissed
    }
}
