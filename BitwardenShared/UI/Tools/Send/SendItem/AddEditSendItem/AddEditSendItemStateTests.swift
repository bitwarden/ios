import BitwardenSdk
import XCTest

@testable import BitwardenShared

class AddEditSendItemStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `availableDeletionDateTypes` returns the available options to display in the deletion date
    /// menu when adding a new send.
    func test_availableDeletionDateTypes_add() {
        let subject = AddEditSendItemState(mode: .add)
        XCTAssertEqual(
            subject.availableDeletionDateTypes,
            [.oneHour, .oneDay, .twoDays, .threeDays, .sevenDays, .thirtyDays],
        )
    }

    /// `availableDeletionDateTypes` returns the available options to display in the deletion date
    /// menu when editing an existing send.
    func test_availableDeletionDateTypes_edit() {
        let deletionDate = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41)
        let subject = AddEditSendItemState(customDeletionDate: deletionDate, mode: .edit)
        XCTAssertEqual(
            subject.availableDeletionDateTypes,
            [.oneHour, .oneDay, .twoDays, .threeDays, .sevenDays, .thirtyDays, .custom(deletionDate)],
        )
    }

    /// `availableDeletionDateTypes` returns the available options to display in the deletion date
    /// menu when adding a new send from the share extension.
    func test_availableDeletionDateTypes_shareExtension() {
        let subject = AddEditSendItemState(mode: .shareExtension(.singleAccount))
        XCTAssertEqual(
            subject.availableDeletionDateTypes,
            [.oneHour, .oneDay, .twoDays, .threeDays, .sevenDays, .thirtyDays],
        )
    }

    func test_newSendView_text() {
        let date = Date(year: 2023, month: 11, day: 5)
        let subject = AddEditSendItemState(
            customDeletionDate: date,
            deletionDate: .custom(date),
            isDeactivateThisSendOn: true,
            isHideMyEmailOn: false,
            isHideTextByDefaultOn: true,
            isOptionsExpanded: true,
            isPasswordVisible: false,
            maximumAccessCount: 42,
            name: "Name",
            notes: "Notes",
            password: "password",
            text: "Text",
            type: .text,
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

    /// `newSendView()` sets the expiration date to the deletion date if the expiration date isn't
    /// `nil` to allow editing an expired send.
    func test_newSendView_text_expired() {
        let deletionDate = Date(year: 2024, month: 1, day: 2)
        let subject = AddEditSendItemState(
            customDeletionDate: deletionDate,
            deletionDate: .custom(deletionDate),
            expirationDate: .distantPast,
        )
        let sendView = subject.newSendView()
        XCTAssertEqual(sendView.deletionDate, deletionDate)
        XCTAssertEqual(sendView.expirationDate, deletionDate)
    }

    func init_sendView_text() {
        let deletionDate = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 11)
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
            deletionDate: deletionDate,
            expirationDate: Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 22),
        )
        let subject = AddEditSendItemState(sendView: sendView)
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
        XCTAssertEqual(subject.customDeletionDate, deletionDate)
        XCTAssertEqual(subject.expirationDate, deletionDate)
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
            expirationDate: Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 22),
        )
        let subject = AddEditSendItemState(sendView: sendView)
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
            Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 11),
        )
        XCTAssertEqual(
            subject.expirationDate,
            Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 22),
        )
    }
}
