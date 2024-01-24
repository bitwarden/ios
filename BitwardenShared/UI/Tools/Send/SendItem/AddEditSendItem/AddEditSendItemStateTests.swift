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

    func init_sendView_text() {
        let sendView = SendView.fixture(
            id: "ID",
            accessId: "ACCESS_ID",
            name: "Name",
            notes: "Notes",
            key: "KEY",
            newPassword: nil,
            hasPassword: false,
            type: .text,
            file: nil,
            text: .init(text: "Text", hidden: false),
            maxAccessCount: 420,
            accessCount: 42,
            disabled: false,
            hideEmail: false,
            revisionDate: Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 0),
            deletionDate: Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 11),
            expirationDate: Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 22)
        )
        let subject = AddEditSendItemState(sendView: sendView, hasPremium: true)
        XCTAssertEqual(subject.id, "ID")
        XCTAssertEqual(subject.accessId, "ACCESS_ID")
        XCTAssertEqual(subject.name, "Name")
        XCTAssertEqual(subject.notes, "Notes")
        XCTAssertEqual(subject.key, "KEY")
        XCTAssertEqual(subject.password, "")
        XCTAssertEqual(subject.isPasswordVisible, false)
        XCTAssertEqual(subject.type, .text)
        XCTAssertNil(subject.fileData)
        XCTAssertNil(subject.fileName)
        XCTAssertNil(subject.fileSize)
        XCTAssertEqual(subject.text, "Text")
        XCTAssertEqual(subject.isHideTextByDefaultOn, false)
        XCTAssertEqual(subject.maximumAccessCount, 420)
        XCTAssertEqual(subject.currentAccessCount, 42)
        XCTAssertEqual(subject.isDeactivateThisSendOn, false)
        XCTAssertEqual(subject.isHideMyEmailOn, false)
        XCTAssertEqual(
            subject.customDeletionDate,
            Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 11)
        )
        XCTAssertEqual(
            subject.customExpirationDate,
            Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 22)
        )
    }

    func init_sendView_file() {
        let sendView = SendView.fixture(
            id: "ID",
            accessId: "ACCESS_ID",
            name: "Name",
            notes: "Notes",
            key: "KEY",
            newPassword: nil,
            hasPassword: false,
            type: .file,
            file: .init(id: "FILE_ID", fileName: "File", size: "420420", sizeName: "420.42 KB"),
            text: nil,
            maxAccessCount: 420,
            accessCount: 42,
            disabled: false,
            hideEmail: false,
            revisionDate: Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 0),
            deletionDate: Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 11),
            expirationDate: Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 22)
        )
        let subject = AddEditSendItemState(sendView: sendView, hasPremium: true)
        XCTAssertEqual(subject.id, "ID")
        XCTAssertEqual(subject.accessId, "ACCESS_ID")
        XCTAssertEqual(subject.name, "Name")
        XCTAssertEqual(subject.notes, "Notes")
        XCTAssertEqual(subject.key, "KEY")
        XCTAssertEqual(subject.password, "")
        XCTAssertEqual(subject.isPasswordVisible, false)
        XCTAssertEqual(subject.type, .text)
        XCTAssertNil(subject.fileData)
        XCTAssertEqual(subject.fileName, "File")
        XCTAssertEqual(subject.fileSize, "420.42 KB")
        XCTAssertEqual(subject.text, "")
        XCTAssertEqual(subject.isHideTextByDefaultOn, false)
        XCTAssertEqual(subject.maximumAccessCount, 420)
        XCTAssertEqual(subject.currentAccessCount, 42)
        XCTAssertEqual(subject.isDeactivateThisSendOn, false)
        XCTAssertEqual(subject.isHideMyEmailOn, false)
        XCTAssertEqual(
            subject.customDeletionDate,
            Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 11)
        )
        XCTAssertEqual(
            subject.customExpirationDate,
            Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 22)
        )
    }
}
