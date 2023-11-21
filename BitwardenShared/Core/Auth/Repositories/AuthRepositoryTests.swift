import BitwardenSdk
import XCTest

@testable import BitwardenShared

class AuthRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var clientCrypto: MockClientCrypto!
    var subject: DefaultAuthRepository!
    var stateService: MockStateService!

    let anneAccount = Account
        .fixture(
            profile: .fixture(
                email: "Anne.Account@bitwarden.com",
                name: "Anne Account",
                userId: "1"
            )
        )

    let beeAccount = Account
        .fixture(
            profile: .fixture(
                email: "bee.account@bitwarden.com",
                userId: "2"
            )
        )

    let claimedAccount = Account
        .fixture(
            profile: .fixture(
                email: "claims@bitwarden.com",
                userId: "3"
            )
        )

    let empty = Account
        .fixture(
            profile: .fixture(
                email: "",
                userId: "4"
            )
        )

    let shortEmail = Account
        .fixture(
            profile: .fixture(
                email: "a@gmail.com",
                userId: "5"
            )
        )

    let shortName = Account
        .fixture(
            profile: .fixture(
                email: "aj@gmail.com",
                name: "AJ",
                userId: "6"
            )
        )

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientCrypto = MockClientCrypto()
        stateService = MockStateService()

        subject = DefaultAuthRepository(
            clientCrypto: clientCrypto,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        clientCrypto = nil
        subject = nil
        stateService = nil
    }

    // MARK: Tests

    /// `getAccounts()` throws an error when the accounts are nil.
    func test_getAccounts_empty() async throws {
        await assertAsyncThrows(error: StateServiceError.noAccounts) {
            _ = try await subject.getAccounts()
        }
    }

    /// `getAccounts()` returns all known accounts.
    ///
    func test_getAccounts_valid() async throws { // swiftlint:disable:this function_body_length
        stateService.accounts = [
            anneAccount,
            beeAccount,
            claimedAccount,
            empty,
            shortEmail,
            shortName,
        ]

        let accounts = try await subject.getAccounts()
        XCTAssertEqual(
            accounts.first,
            ProfileSwitcherItem(
                email: anneAccount.profile.email,
                userId: anneAccount.profile.userId,
                userInitials: "AA"
            )
        )
        XCTAssertEqual(
            accounts[1],
            ProfileSwitcherItem(
                email: beeAccount.profile.email,
                userId: beeAccount.profile.userId,
                userInitials: "BA"
            )
        )
        XCTAssertEqual(
            accounts[2],
            ProfileSwitcherItem(
                email: claimedAccount.profile.email,
                userId: claimedAccount.profile.userId,
                userInitials: "CL"
            )
        )
        XCTAssertEqual(
            accounts[3],
            ProfileSwitcherItem(
                email: "",
                userId: "4",
                userInitials: ".."
            )
        )
        XCTAssertEqual(
            accounts[4],
            ProfileSwitcherItem(
                email: shortEmail.profile.email,
                userId: shortEmail.profile.userId,
                userInitials: "A"
            )
        )
        XCTAssertEqual(
            accounts[5],
            ProfileSwitcherItem(
                email: shortName.profile.email,
                userId: shortName.profile.userId,
                userInitials: "AJ"
            )
        )
    }

    /// `getActiveAccount()` returns a profile switcher item.
    func test_getActiveAccount_empty() async throws {
        stateService.accounts = [
            anneAccount,
        ]

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getActiveAccount()
        }
    }

    /// `getActiveAccount()` returns an account when the active account is valid.
    func test_getActiveAccount_valid() async throws {
        stateService.accounts = [
            anneAccount,
        ]
        stateService.activeAccount = anneAccount

        let active = try await subject.getActiveAccount()
        XCTAssertEqual(
            active,
            ProfileSwitcherItem(
                email: anneAccount.profile.email,
                userId: anneAccount.profile.userId,
                userInitials: "AA"
            )
        )
    }

    /// `getAccount(for:)` returns an account when there is a match.
    func test_getAccountForProfile_match() async throws {
        stateService.accounts = [
            anneAccount,
        ]
        stateService.activeAccount = anneAccount
        let profile = ProfileSwitcherItem(
            email: anneAccount.profile.email,
            userId: anneAccount.profile.userId,
            userInitials: "AA"
        )

        let match = try await subject.getAccount(for: profile.userId)
        XCTAssertEqual(
            match,
            anneAccount
        )
    }

    /// `getAccount(for:)` returns an error when there is no match.
    func test_getAccountForProfile_noMatch() async throws {
        stateService.accounts = [
            anneAccount,
        ]
        stateService.activeAccount = anneAccount
        let profile = ProfileSwitcherItem(
            email: beeAccount.profile.email,
            userId: beeAccount.profile.userId,
            userInitials: "BA"
        )
        await assertAsyncThrows(error: StateServiceError.noAccounts) {
            _ = try await subject.getAccount(for: profile.userId)
        }
    }

    /// `unlockVault(password:)` unlocks the vault with the user's password.
    func test_unlockVault() async throws {
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(encryptedPrivateKey: "PRIVATE_KEY", encryptedUserKey: "USER_KEY"),
        ]

        await assertAsyncDoesNotThrow {
            try await subject.unlockVault(password: "password")
        }

        XCTAssertEqual(
            clientCrypto.initializeCryptoRequest,
            InitCryptoRequest(
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                password: "password",
                userKey: "USER_KEY",
                privateKey: "PRIVATE_KEY",
                organizationKeys: [:]
            )
        )
    }

    /// `unlockVault(password:)` throws an error if the vault is unable to be unlocked.
    func test_unlockVault_error() async {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.unlockVault(password: "")
        }
    }
}
