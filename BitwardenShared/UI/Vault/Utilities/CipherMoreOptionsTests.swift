import BitwardenSdk
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - CipherMoreOptionsTests

class CipherMoreOptionsTests: BitwardenTestCase {
    // MARK: Tests

    /// `applicableMoreOptionsActionKinds(hasPremium:)` returns an empty list for a
    /// decryption-failure cipher.
    func test_applicableMoreOptionsActionKinds_decryptionFailure() {
        let cipher = CipherListView(cipherDecryptFailure: .fixture())
        XCTAssertEqual(cipher.applicableMoreOptionsActionKinds(hasPremium: true), [])
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` excludes `.edit` for a trashed cipher.
    func test_applicableMoreOptionsActionKinds_trashed() {
        let cipher = CipherListView.fixture(type: .identity, deletedDate: .now)
        XCTAssertEqual(cipher.applicableMoreOptionsActionKinds(hasPremium: false), [.view])
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` returns only view/edit/archive for an identity cipher.
    func test_applicableMoreOptionsActionKinds_identity() {
        let cipher = CipherListView.fixture(type: .identity)
        XCTAssertEqual(cipher.applicableMoreOptionsActionKinds(hasPremium: false), [.view, .edit, .archive])
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

    /// `applicableMoreOptionsActionKinds(hasPremium:)` excludes `.copyPassword` when `viewPassword`
    /// is `false`, even if `copyableFields` contains `.loginPassword`.
    func test_applicableMoreOptionsActionKinds_login_noViewPassword() {
        let cipher = CipherListView.fixture(
            type: .login(.fixture()),
            copyableFields: [.loginPassword],
        )
        XCTAssertEqual(cipher.applicableMoreOptionsActionKinds(hasPremium: false), [.view, .edit, .archive])
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

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates drivers license copy action on `copyableFields`.
    func test_applicableMoreOptionsActionKinds_driversLicense() {
        let cipher = CipherListView.fixture(type: .driversLicense, copyableFields: [.driversLicenseLicenseNumber])
        XCTAssertEqual(
            cipher.applicableMoreOptionsActionKinds(hasPremium: false),
            [.view, .edit, .copyLicenseNumber, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates passport copy action on `copyableFields`.
    func test_applicableMoreOptionsActionKinds_passport() {
        let cipher = CipherListView.fixture(type: .passport, copyableFields: [.passportPassportNumber])
        XCTAssertEqual(
            cipher.applicableMoreOptionsActionKinds(hasPremium: false),
            [.view, .edit, .copyPassportNumber, .archive],
        )
    }

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
}
