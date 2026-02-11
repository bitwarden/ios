import BitwardenSdk
import XCTest

@testable import BitwardenShared

class AddEditSendItemStateTests: BitwardenTestCase {
    // MARK: Tests

    // MARK: availableAccessTypes

    /// `availableAccessTypes` returns all options when feature flag is enabled, even without premium.
    /// The premium restriction is handled at the processor level when the user selects "Specific People".
    func test_availableAccessTypes_noPremium_featureFlagEnabled() {
        let subject = AddEditSendItemState(hasPremium: false, isSendEmailVerificationEnabled: true)
        XCTAssertEqual(subject.availableAccessTypes, SendAccessType.allCases)
    }

    /// `availableAccessTypes` returns only basic options when feature flag is disabled.
    func test_availableAccessTypes_featureFlagDisabled() {
        let subject = AddEditSendItemState(hasPremium: true, isSendEmailVerificationEnabled: false)
        XCTAssertEqual(subject.availableAccessTypes, [.anyoneWithLink, .anyoneWithPassword])
    }

    /// `availableAccessTypes` returns all options when user has premium and feature flag is enabled.
    func test_availableAccessTypes_premiumAndFeatureFlag() {
        let subject = AddEditSendItemState(hasPremium: true, isSendEmailVerificationEnabled: true)
        XCTAssertEqual(subject.availableAccessTypes, SendAccessType.allCases)
    }

    // MARK: normalizedRecipientEmails

    /// `normalizedRecipientEmails` applies all transformations: trim, lowercase, and filter.
    func test_normalizedRecipientEmails_allTransformations() {
        let subject = AddEditSendItemState(
            recipientEmails: ["  TEST@Example.COM  ", "", "  Another@TEST.com\n", "   "],
        )
        XCTAssertEqual(subject.normalizedRecipientEmails, ["test@example.com", "another@test.com"])
    }

    /// `normalizedRecipientEmails` returns an empty array when there are no emails.
    func test_normalizedRecipientEmails_empty() {
        let subject = AddEditSendItemState(recipientEmails: [])
        XCTAssertEqual(subject.normalizedRecipientEmails, [])
    }

    /// `normalizedRecipientEmails` filters out empty strings and whitespace-only strings.
    func test_normalizedRecipientEmails_filtersEmptyStrings() {
        let subject = AddEditSendItemState(recipientEmails: ["test@example.com", "", "   ", "\n\t"])
        XCTAssertEqual(subject.normalizedRecipientEmails, ["test@example.com"])
    }

    /// `normalizedRecipientEmails` lowercases all emails.
    func test_normalizedRecipientEmails_lowercases() {
        let subject = AddEditSendItemState(recipientEmails: ["TEST@EXAMPLE.COM", "Another@Example.Com"])
        XCTAssertEqual(subject.normalizedRecipientEmails, ["test@example.com", "another@example.com"])
    }

    /// `normalizedRecipientEmails` trims whitespace and newlines from emails.
    func test_normalizedRecipientEmails_trimsWhitespace() {
        let subject = AddEditSendItemState(recipientEmails: ["  test@example.com  ", "\tanother@example.com\n"])
        XCTAssertEqual(subject.normalizedRecipientEmails, ["test@example.com", "another@example.com"])
    }

    // MARK: availableDeletionDateTypes

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
            accessType: .anyoneWithPassword,
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
        XCTAssertEqual(sendView.authType, .password)
    }

    /// `newSendView()` correctly sets access type and emails for specific people,
    /// filtering empty emails and normalizing (trimming and lowercasing) them.
    func test_newSendView_specificPeople() {
        let date = Date(year: 2023, month: 11, day: 5)
        let subject = AddEditSendItemState(
            accessType: .specificPeople,
            customDeletionDate: date,
            deletionDate: .custom(date),
            name: "Name",
            recipientEmails: ["  TEST@example.com  ", "ANOTHER@Example.COM", "", "   "],
            text: "Text",
            type: .text,
        )
        let sendView = subject.newSendView()
        XCTAssertEqual(sendView.authType, .email)
        XCTAssertEqual(sendView.emails, ["test@example.com", "another@example.com"])
        XCTAssertFalse(sendView.hasPassword)
        XCTAssertNil(sendView.newPassword)
    }

    /// `newSendView()` correctly sets access type for anyone with link.
    func test_newSendView_anyoneWithLink() {
        let date = Date(year: 2023, month: 11, day: 5)
        let subject = AddEditSendItemState(
            accessType: .anyoneWithLink,
            customDeletionDate: date,
            deletionDate: .custom(date),
            name: "Name",
            text: "Text",
            type: .text,
        )
        let sendView = subject.newSendView()
        XCTAssertEqual(sendView.authType, .none)
        XCTAssertTrue(sendView.emails.isEmpty)
        XCTAssertFalse(sendView.hasPassword)
    }

    /// `newSendView()` preserves existing password when editing and no new password is entered.
    func test_newSendView_preservesExistingPassword() {
        let date = Date(year: 2023, month: 11, day: 5)
        let originalSendView = SendView.fixture(hasPassword: true)
        let subject = AddEditSendItemState(
            accessType: .anyoneWithPassword,
            customDeletionDate: date,
            deletionDate: .custom(date),
            mode: .edit,
            name: "Name",
            originalSendView: originalSendView,
            password: "",
            text: "Text",
            type: .text,
        )
        let sendView = subject.newSendView()
        XCTAssertTrue(sendView.hasPassword)
        XCTAssertNil(sendView.newPassword)
    }

    /// `newSendView()` clears password when access type changes from password to link.
    func test_newSendView_clearsPasswordWhenAccessTypeChanges() {
        let date = Date(year: 2023, month: 11, day: 5)
        let originalSendView = SendView.fixture(hasPassword: true)
        let subject = AddEditSendItemState(
            accessType: .anyoneWithLink,
            customDeletionDate: date,
            deletionDate: .custom(date),
            mode: .edit,
            name: "Name",
            originalSendView: originalSendView,
            password: "",
            text: "Text",
            type: .text,
        )
        let sendView = subject.newSendView()
        XCTAssertFalse(sendView.hasPassword)
        XCTAssertNil(sendView.newPassword)
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

    // MARK: init(sendView:) - Access Type Tests

    /// `init(sendView:)` sets access type to "Anyone with password" when hasPassword is true.
    func test_init_sendView_withPassword_setsAnyoneWithPassword() {
        let sendView = SendView.fixture(hasPassword: true, authType: .none)
        let subject = AddEditSendItemState(sendView: sendView)
        XCTAssertEqual(subject.accessType, .anyoneWithPassword)
    }

    /// `init(sendView:)` sets access type to "Anyone with link" when hasPassword is false and authType is none.
    func test_init_sendView_noPassword_setsAnyoneWithLink() {
        let sendView = SendView.fixture(hasPassword: false, authType: .none)
        let subject = AddEditSendItemState(sendView: sendView)
        XCTAssertEqual(subject.accessType, .anyoneWithLink)
    }

    /// `init(sendView:)` sets access type to "Specific people" when authType is email.
    func test_init_sendView_emailAuthType_setsSpecificPeople() {
        let sendView = SendView.fixture(
            hasPassword: false,
            emails: ["test@example.com"],
            authType: .email,
        )
        let subject = AddEditSendItemState(sendView: sendView)
        XCTAssertEqual(subject.accessType, .specificPeople)
        XCTAssertEqual(subject.recipientEmails, ["test@example.com"])
    }

    /// `init(sendView:)` sets access type to "Anyone with password" when authType is password.
    func test_init_sendView_passwordAuthType_setsAnyoneWithPassword() {
        let sendView = SendView.fixture(hasPassword: true, authType: .password)
        let subject = AddEditSendItemState(sendView: sendView)
        XCTAssertEqual(subject.accessType, .anyoneWithPassword)
    }
}
