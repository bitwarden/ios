import BitwardenKit
import BitwardenResources
import XCTest

@testable import BitwardenShared

class AlertPlatformTests: BitwardenTestCase {
    /// `confirmRegularExpressionMatchDetectionAlert(action:)` constructs an `Alert`
    /// with the correct title, message, and Cancel and Yes buttons.
    func test_confirmRegularExpressionMatchDetectionAlert() {
        let subject = Alert.confirmRegularExpressionMatchDetectionAlert {}

        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.areYouSureYouWantToUseX(Localizations.regEx))
        XCTAssertEqual(
            subject.message,
            Localizations.regularExpressionIsAnAdvancedOptionWithIncreasedRiskOfExposingCredentials,
        )
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.yes)
        XCTAssertEqual(subject.alertActions.last?.style, .default)
    }

    /// `confirmStartsWithMatchDetectionAlert(action:)` constructs an `Alert`
    /// with the correct title, message, and Cancel and Yes buttons.
    func test_confirmStartsWithMatchDetectionAlert() {
        let subject = Alert.confirmStartsWithMatchDetectionAlert {}

        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.areYouSureYouWantToUseX(Localizations.startsWith))
        XCTAssertEqual(
            subject.message,
            Localizations.startsWithIsAnAdvancedOptionWithIncreasedRiskOfExposingCredentials,
        )
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.yes)
        XCTAssertEqual(subject.alertActions.last?.style, .default)
    }

    /// `learnMoreAdvancedMatchingDetection(matchingType: action:)` constructs an `Alert`
    /// with the correct title, message, and Cancel and Yes buttons.
    func test_learnMoreAdvancedMatchingDetection() {
        let subject = Alert.learnMoreAdvancedMatchingDetection(UriMatchType.regularExpression.localizedName) {}

        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.keepYourCredentialsSecure)
        XCTAssertEqual(
            subject.message,
            Localizations.learnMoreAboutHowToKeepCredentialsSecureWhenUsingX(
                UriMatchType.regularExpression.localizedName,
            ),
        )
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.close)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.learnMore)
        XCTAssertEqual(subject.alertActions.last?.style, .default)
    }
}
