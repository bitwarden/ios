import BitwardenResources
import XCTest

@testable import BitwardenShared

class ViewSendItemStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `displayShareURL` returns the share URL without a scheme.
    func test_displayShareURL() {
        let subject = ViewSendItemState(
            sendView: .fixture(),
            shareURL: URL(string: "https://send.bitwarden.com/39ngaol3")
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
}
