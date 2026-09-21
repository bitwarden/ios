import BitwardenResources
import XCTest

@testable import BitwardenShared

class ViewSendItemStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `displayShareURL` returns the share URL without a scheme.
    func test_displayShareURL() {
        let subject = ViewSendItemState(
            sendView: .fixture(),
            shareURL: URL(string: "https://send.bitwarden.com/39ngaol3"),
        )
        XCTAssertEqual(subject.displayShareURL, "send.bitwarden.com/39ngaol3")
    }

    /// `displayShareURL` returns `nil` if the share URL is `nil`.
    func test_displayShareURL_nil() {
        let subject = ViewSendItemState(sendView: .fixture())
        XCTAssertNil(subject.displayShareURL)
    }

    /// `navigationTitle` returns the navigation title based on the send's type.
    func test_navigationTitle() {
        let textSubject = ViewSendItemState(sendView: .fixture())
        XCTAssertEqual(textSubject.navigationTitle, Localizations.viewTextSend)

        let fileSubject = ViewSendItemState(sendView: .fixture(type: .file))
        XCTAssertEqual(fileSubject.navigationTitle, Localizations.viewFileSend)
    }

    // MARK: Restriction State Tests (`isDisabled`, `restrictionBannerMessage`, `canMakeCopy`)

    /// A disabled File Send shows the generic non-compliant message and offers no copy, regardless
    /// of whether its type is restricted by policy.
    func test_restrictionState_disabledFileSend() {
        let subject = ViewSendItemState(sendView: .fixture(type: .file, disabled: true))

        XCTAssertTrue(subject.isDisabled)
        XCTAssertEqual(subject.restrictionBannerMessage, Localizations.thisSendIsNotCompliantDescriptionLong)
        XCTAssertFalse(subject.canMakeCopy)
    }

    /// A disabled Text Send whose type is restricted by policy shows the text-restricted message
    /// and offers no copy.
    func test_restrictionState_disabledTextSend_typeRestricted() {
        var subject = ViewSendItemState(sendView: .fixture(type: .text, disabled: true))
        subject.sendPolicyOptions = SendPolicyOptions(enforcedSendType: .file)

        XCTAssertTrue(subject.isDisabled)
        XCTAssertEqual(subject.restrictionBannerMessage, Localizations.textSendsAreNotAllowedDescriptionLong)
        XCTAssertFalse(subject.canMakeCopy)
    }

    /// A disabled Text Send whose type isn't restricted by policy offers the "Make a copy" action.
    func test_restrictionState_disabledTextSend_typeNotRestricted() {
        let subject = ViewSendItemState(sendView: .fixture(type: .text, disabled: true))

        XCTAssertTrue(subject.isDisabled)
        XCTAssertEqual(subject.restrictionBannerMessage, Localizations.toEditThisSendMakeACopyDescriptionLong)
        XCTAssertTrue(subject.canMakeCopy)
    }

    /// A non-disabled Send has no restrictions.
    func test_restrictionState_notDisabled() {
        let subject = ViewSendItemState(sendView: .fixture(disabled: false))
        XCTAssertFalse(subject.isDisabled)
        XCTAssertNil(subject.restrictionBannerMessage)
        XCTAssertFalse(subject.canMakeCopy)
    }
}
