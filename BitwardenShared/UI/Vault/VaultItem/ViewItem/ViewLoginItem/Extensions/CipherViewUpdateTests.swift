import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

final class CipherViewUpdateTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var cipherItemState: CipherItemState!
    var now: Date!
    var timeProvider: MockTimeProvider!
    var subject: BitwardenSdk.CipherView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        now = Date(year: 2024, month: 2, day: 14, hour: 8, minute: 0, second: 0)
        subject = CipherView.loginFixture()
        timeProvider = MockTimeProvider(.mockTime(now))
        cipherItemState = .init(hasPremium: true)
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
        timeProvider = nil
        cipherItemState = nil
    }

    // MARK: Tests

    /// `loginItemState()` doesn't exclude the FIDO2 credential when `excludeFido2Credentials` is false.
    func test_loginItemState_excludeFido2Credential_false() {
        let cipherView = CipherView.fixture(
            login: .fixture(
                fido2Credentials: [
                    .fixture(),
                ],
            ),
        )

        let loginItemState = cipherView.loginItemState(excludeFido2Credentials: false, showTOTP: false)
        XCTAssertEqual(
            loginItemState.fido2Credentials,
            [.fixture()],
        )
    }

    /// `loginItemState()` excludes the FIDO2 credential when `excludeFido2Credentials` is true.
    func test_loginItemState_excludeFido2Credential_true() {
        let cipherView = CipherView.fixture(
            login: .fixture(
                fido2Credentials: [
                    .fixture(),
                ],
            ),
        )

        let loginItemState = cipherView.loginItemState(excludeFido2Credentials: true, showTOTP: false)
        XCTAssertTrue(loginItemState.fido2Credentials.isEmpty)
    }

    /// `driversLicenseItemState()` returns the driver's license item state from the cipher view,
    /// reading every field including the raw date strings without parsing.
    func test_driversLicenseItemState() { // swiftlint:disable:this function_body_length
        let cipherView = CipherView.fixture(type: .driversLicense)
        let withLicense = CipherView(
            id: cipherView.id,
            organizationId: cipherView.organizationId,
            folderId: cipherView.folderId,
            collectionIds: cipherView.collectionIds,
            key: cipherView.key,
            name: cipherView.name,
            notes: cipherView.notes,
            type: .driversLicense,
            login: nil,
            identity: nil,
            card: nil,
            secureNote: nil,
            sshKey: nil,
            bankAccount: nil,
            driversLicense: DriversLicenseView(
                firstName: "Bit",
                middleName: "W",
                lastName: "Warden",
                dateOfBirth: "1989-08-01",
                licenseNumber: "D1234567",
                issuingCountry: "United States",
                issuingState: "California",
                issueDate: "2019-08-01",
                expirationDate: "2029-08-01",
                issuingAuthority: "DMV",
                licenseClass: "C",
            ),
            passport: nil,
            favorite: cipherView.favorite,
            reprompt: cipherView.reprompt,
            organizationUseTotp: cipherView.organizationUseTotp,
            edit: cipherView.edit,
            permissions: cipherView.permissions,
            viewPassword: cipherView.viewPassword,
            localData: cipherView.localData,
            attachments: cipherView.attachments,
            attachmentDecryptionFailures: nil,
            fields: cipherView.fields,
            passwordHistory: cipherView.passwordHistory,
            creationDate: cipherView.creationDate,
            deletedDate: cipherView.deletedDate,
            revisionDate: cipherView.revisionDate,
            archivedDate: cipherView.archivedDate,
        )

        let state = withLicense.driversLicenseItemState()
        XCTAssertEqual(state.firstName, "Bit")
        XCTAssertEqual(state.middleName, "W")
        XCTAssertEqual(state.lastName, "Warden")
        XCTAssertEqual(state.dateOfBirth, "1989-08-01")
        XCTAssertEqual(state.licenseNumber, "D1234567")
        XCTAssertEqual(state.issuingCountry, "United States")
        XCTAssertEqual(state.issuingState, "California")
        XCTAssertEqual(state.issueDate, "2019-08-01")
        XCTAssertEqual(state.expirationDate, "2029-08-01")
        XCTAssertEqual(state.issuingAuthority, "DMV")
        XCTAssertEqual(state.licenseClass, "C")
    }

    /// `driversLicenseItemState()` returns an empty state when there's no `driversLicense` in the cipher view.
    func test_driversLicenseItemState_nil() {
        let cipherView = CipherView.fixture()
        let state = cipherView.driversLicenseItemState()
        XCTAssertEqual(state, DriversLicenseItemState())
    }

    /// `updatedView(with:)` round-trips a driver's license, preserving all 11 fields as strings.
    func test_update_driversLicense_edits_succeeds() {
        cipherItemState.type = .driversLicense
        var expectedLicenseState = DriversLicenseItemState()
        expectedLicenseState.firstName = "Bit"
        expectedLicenseState.middleName = "W"
        expectedLicenseState.lastName = "Warden"
        expectedLicenseState.dateOfBirth = "1989-08-01"
        expectedLicenseState.licenseNumber = "D1234567"
        expectedLicenseState.issuingCountry = "United States"
        expectedLicenseState.issuingState = "California"
        expectedLicenseState.issueDate = "2019-08-01"
        expectedLicenseState.expirationDate = "2029-08-01"
        expectedLicenseState.issuingAuthority = "DMV"
        expectedLicenseState.licenseClass = "C"
        cipherItemState.driversLicenseItemState = expectedLicenseState

        let comparison = subject.updatedView(with: cipherItemState)
        XCTAssertEqual(comparison.type, .driversLicense)
        XCTAssertNil(comparison.login)
        XCTAssertNil(comparison.card)
        XCTAssertNil(comparison.identity)

        XCTAssertEqual(comparison.driversLicenseItemState(), expectedLicenseState)
        XCTAssertEqual(comparison.driversLicense?.dateOfBirth, "1989-08-01")
        XCTAssertEqual(comparison.driversLicense?.issueDate, "2019-08-01")
        XCTAssertEqual(comparison.driversLicense?.expirationDate, "2029-08-01")
    }

    /// `bankAccountItemState()` returns the bank account item state from the cipher view, reading
    /// every field.
    func test_bankAccountItemState() {
        let cipherView = CipherView.fixture(
            bankAccount: BankAccountView(
                bankName: "Bank of America",
                nameOnAccount: "Personal Checking",
                accountType: "checking",
                accountNumber: "1234567890123456",
                routingNumber: "1234567890",
                branchNumber: "100",
                pin: "1234",
                swiftCode: "123234",
                iban: "23423434543",
                bankContactPhone: "123-456-7890",
            ),
            type: .bankAccount,
        )

        let state = cipherView.bankAccountItemState()
        XCTAssertEqual(state.bankName, "Bank of America")
        XCTAssertEqual(state.nameOnAccount, "Personal Checking")
        XCTAssertEqual(state.accountType, .custom(.checking))
        XCTAssertEqual(state.accountNumber, "1234567890123456")
        XCTAssertEqual(state.routingNumber, "1234567890")
        XCTAssertEqual(state.branchNumber, "100")
        XCTAssertEqual(state.pin, "1234")
        XCTAssertEqual(state.swiftCode, "123234")
        XCTAssertEqual(state.iban, "23423434543")
        XCTAssertEqual(state.bankContactPhone, "123-456-7890")
    }

    /// `bankAccountItemState()` returns an empty state when there's no `bankAccount` in the cipher view.
    func test_bankAccountItemState_nil() {
        let cipherView = CipherView.fixture()
        let state = cipherView.bankAccountItemState()
        XCTAssertEqual(state, BankAccountItemState())
    }

    /// `bankAccountItemState()` maps an unrecognized account type to `.default` while still
    /// reading the remaining fields.
    func test_bankAccountItemState_unknownAccountType() {
        let cipherView = CipherView.fixture(
            bankAccount: BankAccountView(
                bankName: "Bank of America",
                nameOnAccount: nil,
                accountType: "not-a-real-type",
                accountNumber: nil,
                routingNumber: nil,
                branchNumber: nil,
                pin: nil,
                swiftCode: nil,
                iban: nil,
                bankContactPhone: nil,
            ),
            type: .bankAccount,
        )

        let state = cipherView.bankAccountItemState()
        XCTAssertEqual(state.accountType, .default)
        XCTAssertEqual(state.bankName, "Bank of America")
    }

    /// `updatedView(with:)` round-trips a bank account, preserving all 10 fields.
    func test_update_bankAccount_edits_succeeds() {
        cipherItemState.type = .bankAccount
        var expectedBankAccountState = BankAccountItemState()
        expectedBankAccountState.bankName = "Bank of America"
        expectedBankAccountState.nameOnAccount = "Personal Checking"
        expectedBankAccountState.accountType = .custom(.checking)
        expectedBankAccountState.accountNumber = "1234567890123456"
        expectedBankAccountState.routingNumber = "1234567890"
        expectedBankAccountState.branchNumber = "100"
        expectedBankAccountState.pin = "1234"
        expectedBankAccountState.swiftCode = "123234"
        expectedBankAccountState.iban = "23423434543"
        expectedBankAccountState.bankContactPhone = "123-456-7890"
        cipherItemState.bankAccountItemState = expectedBankAccountState

        let comparison = subject.updatedView(with: cipherItemState)
        XCTAssertEqual(comparison.type, .bankAccount)
        XCTAssertNil(comparison.login)
        XCTAssertNil(comparison.card)
        XCTAssertNil(comparison.identity)

        XCTAssertEqual(comparison.bankAccountItemState(), expectedBankAccountState)
        XCTAssertEqual(comparison.bankAccount?.accountType, "checking")
        XCTAssertEqual(comparison.bankAccount?.accountNumber, "1234567890123456")
    }

    /// `sshKeyItemState()` returns the correct SSH key item state based on the CIpherView.
    func test_sshKeyItemState() {
        let cipherView = CipherView.fixture(
            sshKey: .fixture(),
            type: .sshKey,
            viewPassword: true,
        )
        let sshKeyItemState = cipherView.sshKeyItemState()
        XCTAssertTrue(sshKeyItemState.canViewPrivateKey)
        XCTAssertFalse(sshKeyItemState.isPrivateKeyVisible)
        XCTAssertEqual(sshKeyItemState.privateKey, "privateKey")
        XCTAssertEqual(sshKeyItemState.publicKey, "publicKey")
        XCTAssertEqual(sshKeyItemState.keyFingerprint, "fingerprint")
    }

    /// `sshKeyItemState()` returns nil if there's no `sshKey` in the cipher view.
    func test_sshKeyItemState_nil() {
        let cipherView = CipherView.fixture(
            sshKey: nil,
            viewPassword: true,
        )
        let sshKeyItemState = cipherView.sshKeyItemState()
        XCTAssertFalse(sshKeyItemState.canViewPrivateKey)
        XCTAssertFalse(sshKeyItemState.isPrivateKeyVisible)
        XCTAssertEqual(sshKeyItemState.privateKey, "")
        XCTAssertEqual(sshKeyItemState.publicKey, "")
        XCTAssertEqual(sshKeyItemState.keyFingerprint, "")
    }

    /// `sshKeyItemState()` returns the correct SSH key item state based on the CIpherView
    /// when `viewPassword` is `false`.
    func test_sshKeyItemState_cantViewPassword() {
        let cipherView = CipherView.fixture(
            sshKey: .fixture(),
            type: .sshKey,
            viewPassword: false,
        )
        let sshKeyItemState = cipherView.sshKeyItemState()
        XCTAssertFalse(sshKeyItemState.canViewPrivateKey)
        XCTAssertFalse(sshKeyItemState.isPrivateKeyVisible)
        XCTAssertEqual(sshKeyItemState.privateKey, "privateKey")
        XCTAssertEqual(sshKeyItemState.publicKey, "publicKey")
        XCTAssertEqual(sshKeyItemState.keyFingerprint, "fingerprint")
    }

    /// `update(archivedDate:)` updates the archived date and preserves all other properties.
    func test_update_archivedDate() {
        let originalCipher = CipherView.fixture(
            archivedDate: nil,
            id: "123",
            name: "Test Cipher",
        )
        let archivedDate = Date(year: 2024, month: 3, day: 15)

        let updatedCipher = originalCipher.update(archivedDate: archivedDate)

        XCTAssertEqual(updatedCipher.archivedDate, archivedDate)
        XCTAssertEqual(updatedCipher.id, originalCipher.id)
        XCTAssertEqual(updatedCipher.name, originalCipher.name)
        XCTAssertEqual(updatedCipher.organizationId, originalCipher.organizationId)
        XCTAssertEqual(updatedCipher.folderId, originalCipher.folderId)
        XCTAssertEqual(updatedCipher.collectionIds, originalCipher.collectionIds)
        XCTAssertEqual(updatedCipher.deletedDate, originalCipher.deletedDate)
        XCTAssertEqual(updatedCipher.type, originalCipher.type)
        XCTAssertEqual(updatedCipher.login, originalCipher.login)
        XCTAssertEqual(updatedCipher.notes, originalCipher.notes)
        XCTAssertEqual(updatedCipher.favorite, originalCipher.favorite)
        XCTAssertEqual(updatedCipher.reprompt, originalCipher.reprompt)
        XCTAssertEqual(updatedCipher.creationDate, originalCipher.creationDate)
        XCTAssertEqual(updatedCipher.revisionDate, originalCipher.revisionDate)
    }

    /// `update(archivedDate:)` sets archived date to nil when unarchiving.
    func test_update_archivedDate_nil() {
        let originalCipher = CipherView.fixture(
            archivedDate: Date(year: 2024, month: 3, day: 15),
            id: "123",
            name: "Test Cipher",
        )

        let updatedCipher = originalCipher.update(archivedDate: nil)

        XCTAssertNil(updatedCipher.archivedDate)
        XCTAssertEqual(updatedCipher.id, originalCipher.id)
        XCTAssertEqual(updatedCipher.name, originalCipher.name)
        XCTAssertEqual(updatedCipher.organizationId, originalCipher.organizationId)
        XCTAssertEqual(updatedCipher.folderId, originalCipher.folderId)
        XCTAssertEqual(updatedCipher.collectionIds, originalCipher.collectionIds)
        XCTAssertEqual(updatedCipher.deletedDate, originalCipher.deletedDate)
        XCTAssertEqual(updatedCipher.type, originalCipher.type)
        XCTAssertEqual(updatedCipher.login, originalCipher.login)
        XCTAssertEqual(updatedCipher.notes, originalCipher.notes)
        XCTAssertEqual(updatedCipher.favorite, originalCipher.favorite)
        XCTAssertEqual(updatedCipher.reprompt, originalCipher.reprompt)
        XCTAssertEqual(updatedCipher.creationDate, originalCipher.creationDate)
        XCTAssertEqual(updatedCipher.revisionDate, originalCipher.revisionDate)
    }

    /// `update(archivedDate:)` updates an existing archived date.
    func test_update_archivedDate_updateExisting() {
        let originalDate = Date(year: 2024, month: 1, day: 1)
        let newDate = Date(year: 2024, month: 3, day: 15)
        let originalCipher = CipherView.fixture(
            archivedDate: originalDate,
            id: "123",
            name: "Test Cipher",
        )

        let updatedCipher = originalCipher.update(archivedDate: newDate)

        XCTAssertEqual(updatedCipher.archivedDate, newDate)
        XCTAssertNotEqual(updatedCipher.archivedDate, originalDate)
        XCTAssertEqual(updatedCipher.id, originalCipher.id)
        XCTAssertEqual(updatedCipher.name, originalCipher.name)
    }

    /// Tests that the update succeeds with new properties.
    func test_update_card_edits_succeeds() {
        cipherItemState.type = .card
        let expectedCardState = CardItemState(
            brand: .custom(.visa),
            cardholderName: "Jane Doe",
            cardNumber: "12345",
            cardSecurityCode: "123",
            expirationMonth: .custom(.apr),
            expirationYear: "1234",
        )
        cipherItemState.cardItemState = expectedCardState
        cipherItemState.identityState = .fixture(
            title: .custom(.mx),
            firstName: "Spontaneous",
            lastName: "Combust",
            middleName: "Lee",
            userName: "sbl-wow",
            company: "ACME",
            socialSecurityNumber: "555-55-5555",
            passportNumber: "55555555",
            licenseNumber: "DL5555555",
            email: "sbl-combust@acme.org",
            phone: "1-555-555-5555",
            address1: "555 Coyote Ln",
            address2: "Apt 2",
            address3: "",
            cityOrTown: "Sedona",
            state: "AZ",
            postalCode: "55555",
            country: "US",
        )

        let comparison = subject.updatedView(with: cipherItemState)
        XCTAssertEqual(comparison.type, .card)
        XCTAssertNil(comparison.login)
        XCTAssertNil(comparison.identity)
        XCTAssertNil(comparison.secureNote)
        XCTAssertNil(comparison.sshKey)

        XCTAssertEqual(comparison.cardItemState(), expectedCardState)

        XCTAssertEqual(comparison.id, subject.id)
        XCTAssertEqual(comparison.organizationId, subject.organizationId)
        XCTAssertEqual(comparison.folderId, subject.folderId)
        XCTAssertEqual(comparison.collectionIds, subject.collectionIds)
        XCTAssertEqual(comparison.name, cipherItemState.name)
    }

    /// Tests that the update succeeds with matching properties.
    func test_update_identity_succeeds() throws {
        var editState = try XCTUnwrap(
            CipherItemState(
                existing: subject,
                hasPremium: true,
            ),
        )
        editState.type = .identity
        editState.identityState = .fixture(
            title: .custom(.mx),
            firstName: "Spontaneous",
            lastName: "Combust",
            middleName: "Lee",
            userName: "sbl-wow",
            company: "ACME",
            socialSecurityNumber: "555-55-5555",
            passportNumber: "55555555",
            licenseNumber: "DL5555555",
            email: "sbl-combust@acme.org",
            phone: "1-555-555-5555",
            address1: "555 Coyote Ln",
            address2: "Apt 2",
            address3: "",
            cityOrTown: "Sedona",
            state: "AZ",
            postalCode: "55555",
            country: "US",
        )
        let comparison = subject.updatedView(with: editState)
        XCTAssertEqual(
            comparison.identity,
            .init(
                identityView: subject.identity,
                identityState: editState.identityState,
            ),
        )
        XCTAssertEqual(comparison.type, .identity)
        XCTAssertNil(comparison.card)
        XCTAssertNil(comparison.login)
        XCTAssertNil(comparison.secureNote)
        XCTAssertNil(comparison.sshKey)
    }

    /// Tests that the update succeeds with new properties.
    func test_update_noEdits_succeeds() {
        let editState = CipherItemState(
            existing: subject,
            hasPremium: true,
        )!
        let comparison = subject.updatedView(with: editState)
        XCTAssertEqual(subject, comparison)
    }

    /// Tests that the update succeeds with new properties.
    func test_update_login_noEdits_succeeds() throws {
        let editState = try XCTUnwrap(
            CipherItemState(
                existing: subject,
                hasPremium: true,
            ),
        )
        let comparison = subject.updatedView(with: editState)
        XCTAssertEqual(subject, comparison)
    }

    /// Tests that the update succeeds with new properties.
    func test_update_login_edits_succeeds() {
        subject = CipherView.loginFixture()
        cipherItemState.type = .login
        cipherItemState.notes = "I have a note"
        cipherItemState.loginState.username = "PASTA"
        cipherItemState.loginState.password = "BATMAN"
        cipherItemState.isFavoriteOn = true
        cipherItemState.isMasterPasswordRePromptOn = true

        let comparison = subject.updatedView(with: cipherItemState)
        XCTAssertEqual(comparison.type, .login)
        XCTAssertNil(comparison.card)
        XCTAssertNil(comparison.identity)
        XCTAssertNil(comparison.secureNote)
        XCTAssertNil(comparison.sshKey)

        XCTAssertEqual(comparison.id, subject.id)
        XCTAssertEqual(comparison.organizationId, subject.organizationId)
        XCTAssertEqual(comparison.folderId, subject.folderId)
        XCTAssertEqual(comparison.collectionIds, subject.collectionIds)
        XCTAssertEqual(comparison.name, cipherItemState.name)
        XCTAssertEqual(comparison.login?.username, cipherItemState.loginState.username)
        XCTAssertEqual(comparison.login?.password, cipherItemState.loginState.password)
        XCTAssertEqual(comparison.notes, cipherItemState.notes)
        XCTAssertEqual(comparison.secureNote, subject.secureNote)
        XCTAssertEqual(comparison.sshKey, subject.sshKey)
        XCTAssertEqual(comparison.favorite, cipherItemState.isFavoriteOn)
        XCTAssertEqual(
            comparison.reprompt,
            cipherItemState.isMasterPasswordRePromptOn ? .password : .none,
        )
        XCTAssertEqual(comparison.organizationUseTotp, false)
        XCTAssertEqual(comparison.edit, true)
        XCTAssertEqual(comparison.viewPassword, true)
        XCTAssertEqual(comparison.localData, subject.localData)
        XCTAssertEqual(comparison.attachments, subject.attachments)
        XCTAssertEqual(comparison.fields, subject.fields)
        XCTAssertEqual(comparison.passwordHistory, subject.passwordHistory)
        XCTAssertEqual(comparison.creationDate, subject.creationDate)
        XCTAssertEqual(comparison.deletedDate, nil)
        XCTAssertEqual(comparison.revisionDate, subject.revisionDate)
    }

    /// Tests that the update succeeds with a new password updating the password history.
    func test_update_login_passwordHistory_succeeds() {
        subject = CipherView.loginFixture(login: .fixture(password: "Old password"))
        cipherItemState.loginState.password = "New password"

        let comparison = subject.updatedView(with: cipherItemState)
        let newPasswordHistory = comparison.passwordHistory

        XCTAssertEqual(newPasswordHistory?.last?.password, "Old password")

        cipherItemState.loginState.password = "Extra newer password"
        let secondComparison = comparison.updatedView(with: cipherItemState)
        let newerPasswordHistory = secondComparison.passwordHistory

        XCTAssertEqual(newerPasswordHistory?.last?.password, "New password")
    }

    /// Tests that the update succeeds when a hidden field change modifies the password history.
    func test_update_login_passwordHistory_hiddenField_succeeds() {
        subject = CipherView.loginFixture(fields: [
            FieldView(
                name: "Name",
                value: "1",
                type: BitwardenSdk.FieldType.hidden,
                linkedId: nil,
            ),
        ])
        cipherItemState.customFieldsState.customFields = [
            CustomFieldState(fieldView: .fixture(value: "2")),
        ]

        let comparison = subject.updatedView(with: cipherItemState)
        let newPasswordHistory = comparison.passwordHistory

        XCTAssertEqual(newPasswordHistory?.last?.password, "Name: 1")

        cipherItemState.customFieldsState.customFields = [
            CustomFieldState(fieldView: .fixture(value: "3")),
        ]

        let secondComparison = comparison.updatedView(with: cipherItemState)
        let newerPasswordHistory = secondComparison.passwordHistory

        XCTAssertEqual(newerPasswordHistory?.last?.password, "Name: 2")
    }

    /// Tests that the update succeeds when a hidden field is deleted modifies the password history..
    func test_update_login_passwordHistory_deleteHiddenField_succeeds() {
        subject = CipherView.loginFixture(fields: [
            FieldView(
                name: "Name",
                value: "1",
                type: BitwardenSdk.FieldType.hidden,
                linkedId: nil,
            ),
        ])
        cipherItemState.customFieldsState.customFields = [
            CustomFieldState(fieldView: .fixture()),
            CustomFieldState(fieldView: .fixture(name: "NewField", value: "1")),
        ]

        let comparison = subject.updatedView(with: cipherItemState)
        let newPasswordHistory = comparison.passwordHistory

        XCTAssertNil(newPasswordHistory)

        cipherItemState.customFieldsState.customFields = [
            CustomFieldState(fieldView: .fixture()),
        ]

        let secondComparison = comparison.updatedView(with: cipherItemState)
        let newerPasswordHistory = secondComparison.passwordHistory

        XCTAssertEqual(newerPasswordHistory?.last?.password, "NewField: 1")
    }

    /// Tests a new hidden field doesn't update the password history.
    func test_update_login_passwordHistory_newHiddenField_succeeds() {
        subject = CipherView.loginFixture(fields: [
            FieldView(
                name: "Name",
                value: "1",
                type: BitwardenSdk.FieldType.hidden,
                linkedId: nil,
            ),
        ])
        cipherItemState.customFieldsState.customFields = [
            CustomFieldState(fieldView: .fixture()),
            CustomFieldState(fieldView: .fixture(name: "NewField", value: "1")),
        ]

        let comparison = subject.updatedView(with: cipherItemState)
        let newPasswordHistory = comparison.passwordHistory

        XCTAssertNil(newPasswordHistory)
    }

    /// Tests that the update succeeds with a new password updating the password revision date.
    func test_update_login_passwordRevisionDate_succeeds() throws {
        subject = CipherView.loginFixture(
            login: .fixture(
                password: "Old password",
                passwordRevisionDate: DateTime.distantPast,
            ),
        )
        cipherItemState.loginState.password = "New password"

        let comparison = subject.updatedView(with: cipherItemState, timeProvider: timeProvider)
        let passwordRevisionDate = try XCTUnwrap(comparison.login?.passwordRevisionDate)

        XCTAssertEqual(passwordRevisionDate, now)
    }

    /// Tests that the password revision date doesn't get updated if the password hasn't changed
    func test_update_login_passwordRevisionDate_noUpdateIfNoNewPassword() throws {
        subject = CipherView.loginFixture(
            login: .fixture(
                password: "Old password",
                passwordRevisionDate: DateTime.distantPast,
            ),
        )
        cipherItemState.loginState.password = "Old password"
        cipherItemState.loginState.username = "New username"

        let comparison = subject.updatedView(with: cipherItemState)
        let passwordRevisionDate = try XCTUnwrap(comparison.login?.passwordRevisionDate)

        XCTAssertEqual(passwordRevisionDate, DateTime.distantPast)
    }

    /// Tests that the update succeeds with updated properties.
    func test_update_secureNote_succeeds() {
        cipherItemState.type = .secureNote
        let comparison = subject.updatedView(with: cipherItemState)
        XCTAssertEqual(comparison.type, .secureNote)
        XCTAssertNil(comparison.card)
        XCTAssertNil(comparison.login)
        XCTAssertNil(comparison.identity)
        XCTAssertNil(comparison.sshKey)
    }

    /// Tests that the update succeeds with updated properties on SSH key type.
    func test_update_sshKey_succeeds() {
        cipherItemState.type = .sshKey
        let comparison = subject.updatedView(with: cipherItemState)
        XCTAssertEqual(comparison.type, .sshKey)
        XCTAssertNil(comparison.card)
        XCTAssertNil(comparison.login)
        XCTAssertNil(comparison.identity)
        XCTAssertNil(comparison.secureNote)
    }

    /// Tests that the update succeeds with new properties.
    func test_update_identity_edits_nilValues() throws {
        let state = CipherItemState(
            existing: subject,
            hasPremium: true,
        )
        var editState = try XCTUnwrap(state)
        editState.type = .identity
        editState.identityState = .fixture(
            title: .default,
        )
        let comparison = subject.updatedView(with: editState)
        XCTAssertEqual(
            comparison.identity,
            .init(
                identityView: subject.identity,
                identityState: editState.identityState,
            ),
        )

        XCTAssertEqual(comparison.type, .identity)
        let identity = try XCTUnwrap(comparison.identity)
        XCTAssertNil(identity.title)
        XCTAssertNil(identity.firstName)
        XCTAssertNil(identity.lastName)
        XCTAssertNil(identity.middleName)
        XCTAssertNil(identity.username)
        XCTAssertNil(identity.company)
        XCTAssertNil(identity.ssn)
        XCTAssertNil(identity.passportNumber)
        XCTAssertNil(identity.licenseNumber)
        XCTAssertNil(identity.email)
        XCTAssertNil(identity.phone)
        XCTAssertNil(identity.address1)
        XCTAssertNil(identity.address2)
        XCTAssertNil(identity.address3)
        XCTAssertNil(identity.city)
        XCTAssertNil(identity.state)
        XCTAssertNil(identity.postalCode)
        XCTAssertNil(identity.country)
    }
} // swiftlint:disable:this file_length
