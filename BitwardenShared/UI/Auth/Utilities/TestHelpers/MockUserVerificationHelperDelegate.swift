import BitwardenKit
import Foundation
import XCTest

@testable import BitwardenShared

class MockUserVerificationHelperDelegate: UserVerificationDelegate {
    var alertShown = [BitwardenKit.Alert]()
    var alertShownHandler: ((BitwardenKit.Alert) async throws -> Void)?
    var alertOnDismissed: (() -> Void)?

    func showAlert(_ alert: BitwardenKit.Alert) {
        alertShown.append(alert)
        Task {
            do {
                try await alertShownHandler?(alert)
            } catch {
                XCTFail("Error calling alert shown handler: \(error)")
            }
        }
    }

    func showAlert(_ alert: BitwardenKit.Alert, onDismissed: (() -> Void)?) {
        showAlert(alert)
        alertOnDismissed = onDismissed
    }
}
