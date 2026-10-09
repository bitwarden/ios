import BitwardenResources
import BitwardenSdk
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - MoreOptionsActionKindTests

class MoreOptionsActionKindTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: applicableMoreOptionsActionKinds Tests

    /// `applicableMoreOptionsActionKinds(hasPremium:)` includes `.archive` for a non-archived,
    /// non-deleted cipher, and `.unarchive` for an archived cipher.
    func test_applicableMoreOptionsActionKinds_archiveUnarchive() {
        let archivable = CipherListView.fixture(type: .identity, deletedDate: nil, archivedDate: nil)
        XCTAssertEqual(archivable.applicableMoreOptionsActionKinds(hasPremium: false), [.view, .edit, .archive])

        let archived = CipherListView.fixture(type: .identity, deletedDate: nil, archivedDate: .now)
        XCTAssertEqual(archived.applicableMoreOptionsActionKinds(hasPremium: false), [.view, .edit, .unarchive])

        let trashed = CipherListView.fixture(type: .identity, deletedDate: .now)
        XCTAssertEqual(trashed.applicableMoreOptionsActionKinds(hasPremium: false), [.view])
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates bank account copy actions on `copyableFields`.
    func test_applicableMoreOptionsActionKinds_bankAccount() {
        let cipher = CipherListView.fixture(
            type: .bankAccount(.init(accountNumber: nil, accountType: nil)),
            copyableFields: [.bankAccountAccountNumber, .bankAccountRoutingNumber],
        )
        XCTAssertEqual(
            cipher.applicableMoreOptionsActionKinds(hasPremium: false),
            [.view, .edit, .copyAccountNumber, .copyRoutingNumber, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates card copy actions on `copyableFields`.
    func test_applicableMoreOptionsActionKinds_card() {
        let noData = CipherListView.fixture(type: .card(.fixture()))
        XCTAssertEqual(noData.applicableMoreOptionsActionKinds(hasPremium: false), [.view, .edit, .archive])

        let withData = CipherListView.fixture(
            type: .card(.fixture()),
            copyableFields: [.cardNumber, .cardSecurityCode],
        )
        XCTAssertEqual(
            withData.applicableMoreOptionsActionKinds(hasPremium: false),
            [.view, .edit, .copyCardNumber, .copySecurityCode, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` returns an empty list for a
    /// decryption-failure cipher.
    func test_applicableMoreOptionsActionKinds_decryptionFailure() {
        let cipher = CipherListView(cipherDecryptFailure: .fixture())
        XCTAssertEqual(cipher.applicableMoreOptionsActionKinds(hasPremium: true), [])
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates drivers license copy action on `copyableFields`.
    func test_applicableMoreOptionsActionKinds_driversLicense() {
        let cipher = CipherListView.fixture(type: .driversLicense, copyableFields: [.driversLicenseLicenseNumber])
        XCTAssertEqual(
            cipher.applicableMoreOptionsActionKinds(hasPremium: false),
            [.view, .edit, .copyLicenseNumber, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` returns only view/edit/archive for an identity cipher.
    func test_applicableMoreOptionsActionKinds_identity() {
        let cipher = CipherListView.fixture(type: .identity)
        XCTAssertEqual(cipher.applicableMoreOptionsActionKinds(hasPremium: false), [.view, .edit, .archive])
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates login copy/launch actions on
    /// `copyableFields`, `viewPassword`, Premium/organization TOTP, and a parseable URI.
    func test_applicableMoreOptionsActionKinds_login() {
        let noData = CipherListView.fixture(type: .login(.fixture()))
        XCTAssertEqual(noData.applicableMoreOptionsActionKinds(hasPremium: false), [.view, .edit, .archive])

        let withData = CipherListView.fixture(
            type: .login(.fixture(uris: [.fixture(uri: URL.example.relativeString)])),
            viewPassword: true,
            copyableFields: [.loginUsername, .loginPassword, .loginTotp],
        )
        XCTAssertEqual(
            withData.applicableMoreOptionsActionKinds(hasPremium: true),
            [.view, .edit, .copyUsername, .copyPassword, .copyTotp, .launch, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` excludes `.copyTotp` when the account has no
    /// Premium and the organization doesn't use TOTP.
    func test_applicableMoreOptionsActionKinds_login_copyTotp_noPremium() {
        let cipher = CipherListView.fixture(type: .login(.fixture()), copyableFields: [.loginTotp])
        XCTAssertEqual(cipher.applicableMoreOptionsActionKinds(hasPremium: false), [.view, .edit, .archive])
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` includes `.copyTotp` when the organization
    /// uses TOTP even without Premium.
    func test_applicableMoreOptionsActionKinds_login_copyTotp_organizationUseTotp() {
        let cipher = CipherListView.fixture(
            type: .login(.fixture()),
            organizationUseTotp: true,
            copyableFields: [.loginTotp],
        )
        XCTAssertEqual(
            cipher.applicableMoreOptionsActionKinds(hasPremium: false),
            [.view, .edit, .copyTotp, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` excludes `.copyPassword` when `viewPassword`
    /// is `false`, even if `copyableFields` contains `.loginPassword`.
    func test_applicableMoreOptionsActionKinds_login_noViewPassword() {
        let cipher = CipherListView.fixture(
            type: .login(.fixture()),
            copyableFields: [.loginPassword],
        )
        XCTAssertEqual(cipher.applicableMoreOptionsActionKinds(hasPremium: false), [.view, .edit, .archive])
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates passport copy action on `copyableFields`.
    func test_applicableMoreOptionsActionKinds_passport() {
        let cipher = CipherListView.fixture(type: .passport, copyableFields: [.passportPassportNumber])
        XCTAssertEqual(
            cipher.applicableMoreOptionsActionKinds(hasPremium: false),
            [.view, .edit, .copyPassportNumber, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates secure note copy action on `copyableFields`.
    func test_applicableMoreOptionsActionKinds_secureNote() {
        let noData = CipherListView.fixture(type: .secureNote)
        XCTAssertEqual(noData.applicableMoreOptionsActionKinds(hasPremium: false), [.view, .edit, .archive])

        let withData = CipherListView.fixture(type: .secureNote, copyableFields: [.secureNotes])
        XCTAssertEqual(
            withData.applicableMoreOptionsActionKinds(hasPremium: false),
            [.view, .edit, .copyNotes, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates SSH key copy actions on `copyableFields`
    /// and `viewPassword` for the private key.
    func test_applicableMoreOptionsActionKinds_sshKey() {
        let noViewPassword = CipherListView.fixture(type: .sshKey, copyableFields: [.sshKey])
        XCTAssertEqual(
            noViewPassword.applicableMoreOptionsActionKinds(hasPremium: false),
            [.view, .edit, .copyPublicKey, .copyFingerprint, .archive],
        )

        let withViewPassword = CipherListView.fixture(
            type: .sshKey,
            viewPassword: true,
            copyableFields: [.sshKey],
        )
        XCTAssertEqual(
            withViewPassword.applicableMoreOptionsActionKinds(hasPremium: false),
            [.view, .edit, .copyPublicKey, .copyPrivateKey, .copyFingerprint, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` excludes `.edit` for a trashed cipher.
    func test_applicableMoreOptionsActionKinds_trashed() {
        let cipher = CipherListView.fixture(type: .identity, deletedDate: .now)
        XCTAssertEqual(cipher.applicableMoreOptionsActionKinds(hasPremium: false), [.view])
    }

    // MARK: localizedName Tests

    /// `localizedName` is non-empty for every kind.
    func test_localizedName() {
        for kind in MoreOptionsActionKind.allCases {
            XCTAssertFalse(kind.localizedName.isEmpty, "\(kind)")
        }
        XCTAssertEqual(MoreOptionsActionKind.copyCardNumber.localizedName, Localizations.copyNumber)
        XCTAssertEqual(MoreOptionsActionKind.view.localizedName, Localizations.view)
    }

    // MARK: moreOptionsAction Tests

    /// `moreOptionsAction(cipherView:itemId:)` maps the bank account kinds to copy actions.
    func test_moreOptionsAction_bankAccount() {
        let cipher = CipherView.fixture(
            bankAccount: .fixture(accountNumber: "1234567890", routingNumber: "021000021"),
            id: "123",
            type: .bankAccount,
        )

        XCTAssertEqual(
            MoreOptionsActionKind.copyAccountNumber.moreOptionsAction(cipherView: cipher, itemId: "123"),
            .copy(
                toast: Localizations.accountNumber,
                value: "1234567890",
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: nil,
            ),
        )
        XCTAssertEqual(
            MoreOptionsActionKind.copyRoutingNumber.moreOptionsAction(cipherView: cipher, itemId: "123"),
            .copy(
                toast: Localizations.routingNumber,
                value: "021000021",
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: nil,
            ),
        )
    }

    /// `moreOptionsAction(cipherView:itemId:)` maps the card kinds to copy actions.
    func test_moreOptionsAction_card() {
        let cipher = CipherView.fixture(card: .fixture(code: "123", number: "4111"), id: "123", type: .card)

        XCTAssertEqual(
            MoreOptionsActionKind.copyCardNumber.moreOptionsAction(cipherView: cipher, itemId: "123"),
            .copy(
                toast: Localizations.number,
                value: "4111",
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: nil,
            ),
        )
        XCTAssertEqual(
            MoreOptionsActionKind.copySecurityCode.moreOptionsAction(cipherView: cipher, itemId: "123"),
            .copy(
                toast: Localizations.securityCode,
                value: "123",
                requiresMasterPasswordReprompt: true,
                logEvent: .cipherClientCopiedCardCode,
                cipherId: "123",
            ),
        )
    }

    /// `moreOptionsAction(cipherView:itemId:)` maps the drivers license kind to a copy action.
    func test_moreOptionsAction_driversLicense() {
        let cipher = CipherView.fixture(driversLicense: .fixture(), id: "123", type: .driversLicense)

        XCTAssertEqual(
            MoreOptionsActionKind.copyLicenseNumber.moreOptionsAction(cipherView: cipher, itemId: "123"),
            .copy(
                toast: Localizations.licenseNumber,
                value: "D1234567",
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: "123",
            ),
        )
    }

    /// `moreOptionsAction(cipherView:itemId:)` maps the login kinds to their actions.
    func test_moreOptionsAction_login() {
        let cipher = CipherView.fixture(
            id: "123",
            login: .fixture(
                password: "password",
                uris: [.fixture(uri: "https://example.com")],
                username: "username",
                totp: "totpKey",
            ),
            type: .login,
            viewPassword: true,
        )

        XCTAssertEqual(
            MoreOptionsActionKind.copyUsername.moreOptionsAction(cipherView: cipher, itemId: "123"),
            .copy(
                toast: Localizations.username,
                value: "username",
                requiresMasterPasswordReprompt: false,
                logEvent: nil,
                cipherId: nil,
            ),
        )
        XCTAssertEqual(
            MoreOptionsActionKind.copyPassword.moreOptionsAction(cipherView: cipher, itemId: "123"),
            .copy(
                toast: Localizations.password,
                value: "password",
                requiresMasterPasswordReprompt: true,
                logEvent: .cipherClientCopiedPassword,
                cipherId: "123",
            ),
        )
        XCTAssertEqual(
            MoreOptionsActionKind.copyTotp.moreOptionsAction(cipherView: cipher, itemId: "123"),
            .copyTotp(totpKey: TOTPKeyModel(authenticatorKey: "totpKey")),
        )
        XCTAssertEqual(
            MoreOptionsActionKind.launch.moreOptionsAction(cipherView: cipher, itemId: "123"),
            .launch(url: URL(string: "https://example.com")!),
        )
    }

    /// `moreOptionsAction(cipherView:itemId:)` returns `nil` when the field for the kind is missing.
    func test_moreOptionsAction_missingField() {
        let cipher = CipherView.fixture(id: "123", login: .fixture(password: nil, username: nil), type: .login)

        for kind in [
            MoreOptionsActionKind.copyAccountNumber, .copyCardNumber, .copyFingerprint, .copyLicenseNumber,
            .copyNotes, .copyPassword, .copyPassportNumber, .copyPrivateKey, .copyPublicKey,
            .copyRoutingNumber, .copySecurityCode, .copyTotp, .copyUsername, .launch,
        ] {
            XCTAssertNil(kind.moreOptionsAction(cipherView: cipher, itemId: "123"), "\(kind)")
        }
    }

    /// `moreOptionsAction(cipherView:itemId:)` maps the navigation and archive kinds to their actions.
    func test_moreOptionsAction_navigationAndArchive() {
        let cipher = CipherView.fixture(id: "123")

        XCTAssertEqual(
            MoreOptionsActionKind.view.moreOptionsAction(cipherView: cipher, itemId: "item"),
            .view(id: "item"),
        )
        XCTAssertEqual(
            MoreOptionsActionKind.edit.moreOptionsAction(cipherView: cipher, itemId: "item"),
            .edit(cipherView: cipher),
        )
        XCTAssertEqual(
            MoreOptionsActionKind.archive.moreOptionsAction(cipherView: cipher, itemId: "item"),
            .archive(cipherView: cipher),
        )
        XCTAssertEqual(
            MoreOptionsActionKind.unarchive.moreOptionsAction(cipherView: cipher, itemId: "item"),
            .unarchive(cipherView: cipher),
        )
    }

    /// `moreOptionsAction(cipherView:itemId:)` returns `nil` for the password and private key kinds
    /// when the cipher doesn't allow viewing its password.
    func test_moreOptionsAction_noViewPassword() {
        let login = CipherView.fixture(
            id: "123",
            login: .fixture(password: "password"),
            type: .login,
            viewPassword: false,
        )
        XCTAssertNil(MoreOptionsActionKind.copyPassword.moreOptionsAction(cipherView: login, itemId: "123"))

        let sshKey = CipherView.fixture(id: "123", sshKey: .fixture(), type: .sshKey, viewPassword: false)
        XCTAssertNil(MoreOptionsActionKind.copyPrivateKey.moreOptionsAction(cipherView: sshKey, itemId: "123"))
        XCTAssertNotNil(MoreOptionsActionKind.copyPublicKey.moreOptionsAction(cipherView: sshKey, itemId: "123"))
    }

    /// `moreOptionsAction(cipherView:itemId:)` maps the passport kind to a copy action.
    func test_moreOptionsAction_passport() {
        let cipher = CipherView.fixture(id: "123", passport: .fixture(), type: .passport)

        XCTAssertEqual(
            MoreOptionsActionKind.copyPassportNumber.moreOptionsAction(cipherView: cipher, itemId: "123"),
            .copy(
                toast: Localizations.passportNumber,
                value: "P1234567",
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: "123",
            ),
        )
    }

    /// `moreOptionsAction(cipherView:itemId:)` maps the secure note kind to a copy action.
    func test_moreOptionsAction_secureNote() {
        let cipher = CipherView.fixture(id: "123", notes: "some notes", type: .secureNote)

        XCTAssertEqual(
            MoreOptionsActionKind.copyNotes.moreOptionsAction(cipherView: cipher, itemId: "123"),
            .copy(
                toast: Localizations.notes,
                value: "some notes",
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: nil,
            ),
        )
    }

    /// `moreOptionsAction(cipherView:itemId:)` maps the SSH key kinds to copy actions.
    func test_moreOptionsAction_sshKey() {
        let cipher = CipherView.fixture(id: "123", sshKey: .fixture(), type: .sshKey, viewPassword: true)

        XCTAssertEqual(
            MoreOptionsActionKind.copyPublicKey.moreOptionsAction(cipherView: cipher, itemId: "123"),
            .copy(
                toast: Localizations.publicKey,
                value: "publicKey",
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: "123",
            ),
        )
        XCTAssertEqual(
            MoreOptionsActionKind.copyPrivateKey.moreOptionsAction(cipherView: cipher, itemId: "123"),
            .copy(
                toast: Localizations.privateKey,
                value: "privateKey",
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: "123",
            ),
        )
        XCTAssertEqual(
            MoreOptionsActionKind.copyFingerprint.moreOptionsAction(cipherView: cipher, itemId: "123"),
            .copy(
                toast: Localizations.fingerprint,
                value: "fingerprint",
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: "123",
            ),
        )
    }
} // swiftlint:disable:this file_length
