import BitwardenSdk
import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - CipherMoreOptionsTests

struct CipherMoreOptionsTests {
    // MARK: Tests

    /// `applicableMoreOptionsActionKinds(hasPremium:)` returns an empty list for a
    /// decryption-failure cipher.
    @Test
    func applicableMoreOptionsActionKinds_decryptionFailure() {
        let cipher = CipherListView(cipherDecryptFailure: .fixture())
        #expect(cipher.applicableMoreOptionsActionKinds(hasPremium: true).isEmpty)
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` excludes `.edit` for a trashed cipher.
    @Test
    func applicableMoreOptionsActionKinds_trashed() {
        let cipher = CipherListView.fixture(type: .identity, deletedDate: .now)
        #expect(cipher.applicableMoreOptionsActionKinds(hasPremium: false) == [.view])
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` returns only view/edit/archive for an identity cipher.
    @Test
    func applicableMoreOptionsActionKinds_identity() {
        let cipher = CipherListView.fixture(type: .identity)
        #expect(cipher.applicableMoreOptionsActionKinds(hasPremium: false) == [.view, .edit, .archive])
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates card copy actions on `copyableFields`.
    @Test
    func applicableMoreOptionsActionKinds_card() {
        let noData = CipherListView.fixture(type: .card(.fixture()))
        #expect(noData.applicableMoreOptionsActionKinds(hasPremium: false) == [.view, .edit, .archive])

        let withData = CipherListView.fixture(
            type: .card(.fixture()),
            copyableFields: [.cardNumber, .cardSecurityCode],
        )
        #expect(
            withData.applicableMoreOptionsActionKinds(hasPremium: false)
                == [.view, .edit, .copyCardNumber, .copySecurityCode, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates login copy/launch actions on
    /// `copyableFields`, `viewPassword`, Premium/organization TOTP, and a parseable URI.
    @Test
    func applicableMoreOptionsActionKinds_login() {
        let noData = CipherListView.fixture(type: .login(.fixture()))
        #expect(noData.applicableMoreOptionsActionKinds(hasPremium: false) == [.view, .edit, .archive])

        let withData = CipherListView.fixture(
            type: .login(.fixture(uris: [.fixture(uri: URL.example.relativeString)])),
            viewPassword: true,
            copyableFields: [.loginUsername, .loginPassword, .loginTotp],
        )
        #expect(
            withData.applicableMoreOptionsActionKinds(hasPremium: true)
                == [.view, .edit, .copyUsername, .copyPassword, .copyTotp, .launch, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` excludes `.copyPassword` when `viewPassword`
    /// is `false`, even if `copyableFields` contains `.loginPassword`.
    @Test
    func applicableMoreOptionsActionKinds_login_noViewPassword() {
        let cipher = CipherListView.fixture(
            type: .login(.fixture()),
            copyableFields: [.loginPassword],
        )
        #expect(cipher.applicableMoreOptionsActionKinds(hasPremium: false) == [.view, .edit, .archive])
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` excludes `.copyTotp` when the account has no
    /// Premium and the organization doesn't use TOTP.
    @Test
    func applicableMoreOptionsActionKinds_login_copyTotp_noPremium() {
        let cipher = CipherListView.fixture(type: .login(.fixture()), copyableFields: [.loginTotp])
        #expect(cipher.applicableMoreOptionsActionKinds(hasPremium: false) == [.view, .edit, .archive])
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` includes `.copyTotp` when the organization
    /// uses TOTP even without Premium.
    @Test
    func applicableMoreOptionsActionKinds_login_copyTotp_organizationUseTotp() {
        let cipher = CipherListView.fixture(
            type: .login(.fixture()),
            organizationUseTotp: true,
            copyableFields: [.loginTotp],
        )
        #expect(
            cipher.applicableMoreOptionsActionKinds(hasPremium: false)
                == [.view, .edit, .copyTotp, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates secure note copy action on `copyableFields`.
    @Test
    func applicableMoreOptionsActionKinds_secureNote() {
        let noData = CipherListView.fixture(type: .secureNote)
        #expect(noData.applicableMoreOptionsActionKinds(hasPremium: false) == [.view, .edit, .archive])

        let withData = CipherListView.fixture(type: .secureNote, copyableFields: [.secureNotes])
        #expect(
            withData.applicableMoreOptionsActionKinds(hasPremium: false)
                == [.view, .edit, .copyNotes, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates SSH key copy actions on `copyableFields`
    /// and `viewPassword` for the private key.
    @Test
    func applicableMoreOptionsActionKinds_sshKey() {
        let noViewPassword = CipherListView.fixture(type: .sshKey, copyableFields: [.sshKey])
        #expect(
            noViewPassword.applicableMoreOptionsActionKinds(hasPremium: false)
                == [.view, .edit, .copyPublicKey, .copyFingerprint, .archive],
        )

        let withViewPassword = CipherListView.fixture(
            type: .sshKey,
            viewPassword: true,
            copyableFields: [.sshKey],
        )
        #expect(
            withViewPassword.applicableMoreOptionsActionKinds(hasPremium: false)
                == [.view, .edit, .copyPublicKey, .copyPrivateKey, .copyFingerprint, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates bank account copy actions on `copyableFields`.
    @Test
    func applicableMoreOptionsActionKinds_bankAccount() {
        let cipher = CipherListView.fixture(
            type: .bankAccount(.init(accountNumber: nil, accountType: nil)),
            copyableFields: [.bankAccountAccountNumber, .bankAccountRoutingNumber],
        )
        #expect(
            cipher.applicableMoreOptionsActionKinds(hasPremium: false)
                == [.view, .edit, .copyAccountNumber, .copyRoutingNumber, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates drivers license copy action on `copyableFields`.
    @Test
    func applicableMoreOptionsActionKinds_driversLicense() {
        let cipher = CipherListView.fixture(type: .driversLicense, copyableFields: [.driversLicenseLicenseNumber])
        #expect(
            cipher.applicableMoreOptionsActionKinds(hasPremium: false)
                == [.view, .edit, .copyLicenseNumber, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` gates passport copy action on `copyableFields`.
    @Test
    func applicableMoreOptionsActionKinds_passport() {
        let cipher = CipherListView.fixture(type: .passport, copyableFields: [.passportPassportNumber])
        #expect(
            cipher.applicableMoreOptionsActionKinds(hasPremium: false)
                == [.view, .edit, .copyPassportNumber, .archive],
        )
    }

    /// `applicableMoreOptionsActionKinds(hasPremium:)` includes `.archive` for a non-archived,
    /// non-deleted cipher, and `.unarchive` for an archived cipher.
    @Test
    func applicableMoreOptionsActionKinds_archiveUnarchive() {
        let archivable = CipherListView.fixture(type: .identity, deletedDate: nil, archivedDate: nil)
        #expect(archivable.applicableMoreOptionsActionKinds(hasPremium: false) == [.view, .edit, .archive])

        let archived = CipherListView.fixture(type: .identity, deletedDate: nil, archivedDate: .now)
        #expect(archived.applicableMoreOptionsActionKinds(hasPremium: false) == [.view, .edit, .unarchive])

        let trashed = CipherListView.fixture(type: .identity, deletedDate: .now)
        #expect(trashed.applicableMoreOptionsActionKinds(hasPremium: false) == [.view])
    }
}
