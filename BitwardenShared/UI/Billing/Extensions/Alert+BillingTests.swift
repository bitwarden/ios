// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenResources
import XCTest

@testable import BitwardenShared

// MARK: - AlertBillingTests

class AlertBillingTests: BitwardenTestCase {
    // MARK: Tests

    /// `paymentNotReceivedYet(goBackHandler:)` builds an `Alert` with the correct title, message, and actions.
    func test_paymentNotReceivedYet() {
        let subject = Alert.paymentNotReceivedYet {}

        XCTAssertEqual(subject.title, Localizations.paymentNotReceivedYet)
        XCTAssertEqual(subject.message, Localizations.returnToStripeInYourBrowserToFinishYourUpgradeDescriptionLong)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)

        let closeAction = subject.alertActions[0]
        XCTAssertEqual(closeAction.title, Localizations.close)
        XCTAssertEqual(closeAction.style, .cancel)

        let goBackAction = subject.alertActions[1]
        XCTAssertEqual(goBackAction.title, Localizations.goBack)
        XCTAssertEqual(goBackAction.style, .default)
    }

    /// `secureCheckoutDidntLoad(tryAgainHandler:)` builds an `Alert` with the correct title, message, and actions.
    func test_secureCheckoutDidntLoad() {
        let subject = Alert.secureCheckoutDidntLoad {}

        XCTAssertEqual(subject.title, Localizations.secureCheckoutDidntLoad)
        XCTAssertEqual(subject.message, Localizations.weHadTroubleOpeningThePaymentPageDescriptionLong)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)

        let closeAction = subject.alertActions[0]
        XCTAssertEqual(closeAction.title, Localizations.close)
        XCTAssertEqual(closeAction.style, .cancel)

        let tryAgainAction = subject.alertActions[1]
        XCTAssertEqual(tryAgainAction.title, Localizations.tryAgain)
        XCTAssertEqual(tryAgainAction.style, .default)
    }

    /// `upgradePending(syncNowHandler:)` builds an `Alert` with the correct title, message, and actions.
    func test_upgradePending() {
        let subject = Alert.upgradePending {}

        XCTAssertEqual(subject.title, Localizations.upgradePending)
        XCTAssertEqual(subject.message, Localizations.yourUpgradeIsBeingProcessedDescriptionLong)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)

        let continueAction = subject.alertActions[0]
        XCTAssertEqual(continueAction.title, Localizations.continue)
        XCTAssertEqual(continueAction.style, .cancel)

        let syncNowAction = subject.alertActions[1]
        XCTAssertEqual(syncNowAction.title, Localizations.syncNow)
        XCTAssertEqual(syncNowAction.style, .default)
    }
}
