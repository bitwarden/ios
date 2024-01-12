import BitwardenSdk
import XCTest

@testable import BitwardenShared

class AddEditSendItemStateTests: BitwardenTestCase {
    // MARK: Tests

    func test_newSendView_text() {
        let date = Date(year: 2023, month: 11, day: 5)
        let subject = AddEditSendItemState(
            customDeletionDate: date,
            customExpirationDate: date,
            deletionDate: .custom,
            expirationDate: .never,
            isDeactivateThisSendOn: true,
            isHideMyEmailOn: false,
            isHideTextByDefaultOn: true,
            isPasswordVisible: false,
            isShareOnSaveOn: true,
            isOptionsExpanded: true,
            maximumAccessCount: 42,
            name: "Name",
            notes: "Notes",
            password: "password",
            text: "Text",
            type: .text
        )
        let sendView = subject.newSendView()
        XCTAssertNil(sendView.id)
        XCTAssertNil(sendView.accessId)
        XCTAssertEqual(sendView.name, "Name")
        XCTAssertEqual(sendView.notes, "Notes")
        XCTAssertNil(sendView.key)
        XCTAssertEqual(sendView.newPassword, "password")
        XCTAssertEqual(sendView.hasPassword, true)
        XCTAssertEqual(sendView.type, .text)
        XCTAssertNil(sendView.file)
        XCTAssertEqual(sendView.text?.text, "Text")
        XCTAssertEqual(sendView.text?.hidden, true)
        XCTAssertEqual(sendView.maxAccessCount, 42)
        XCTAssertEqual(sendView.accessCount, 0)
        XCTAssertEqual(sendView.disabled, true)
        XCTAssertEqual(sendView.hideEmail, false)
        XCTAssertEqual(sendView.revisionDate.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(sendView.deletionDate, date)
        XCTAssertEqual(sendView.expirationDate, nil)
    }
}
