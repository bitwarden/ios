import BitwardenSdk
import XCTest

@testable import BitwardenShared

// swiftlint:disable:next type_body_length
class AuthRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var clientCrypto: MockClientCrypto!
    var subject: DefaultAuthRepository!
    var stateService: MockStateService!

    let anneAccount = Account(
        profile: .init(
            avatarColor: nil,
            email: "Anne.Account@bitwarden.com",
            emailVerified: nil,
            forcePasswordResetReason: nil,
            hasPremiumPersonally: nil,
            kdfIterations: nil,
            kdfMemory: nil,
            kdfParallelism: nil,
            kdfType: nil,
            name: "Anne Account",
            orgIdentifier: nil,
            stamp: nil,
            userDecryptionOptions: nil,
            userId: UUID().uuidString
        ),
        settings: .init(environmentUrls: nil),
        tokens: .init(
            accessToken: "",
            refreshToken: ""
        )
    )
    let beeAccount = Account(
        profile: .init(
            avatarColor: nil,
            email: "bee.account@bitwarden.com",
            emailVerified: nil,
            forcePasswordResetReason: nil,
            hasPremiumPersonally: nil,
            kdfIterations: nil,
            kdfMemory: nil,
            kdfParallelism: nil,
            kdfType: nil,
            name: nil,
            orgIdentifier: nil,
            stamp: nil,
            userDecryptionOptions: nil,
            userId: UUID().uuidString
        ),
        settings: .init(environmentUrls: nil),
        tokens: .init(
            accessToken: "",
            refreshToken: ""
        )
    )
    let claimedAccount = Account(
        profile: .init(
            avatarColor: nil,
            email: "claims@bitwarden.com",
            emailVerified: nil,
            forcePasswordResetReason: nil,
            hasPremiumPersonally: nil,
            kdfIterations: nil,
            kdfMemory: nil,
            kdfParallelism: nil,
            kdfType: nil,
            name: nil,
            orgIdentifier: nil,
            stamp: nil,
            userDecryptionOptions: nil,
            userId: UUID().uuidString
        ),
        settings: .init(environmentUrls: nil),
        tokens: .init(
            accessToken: "",
            refreshToken: ""
        )
    )
    let empty = Account(
        profile: .init(
            avatarColor: nil,
            email: "",
            emailVerified: nil,
            forcePasswordResetReason: nil,
            hasPremiumPersonally: nil,
            kdfIterations: nil,
            kdfMemory: nil,
            kdfParallelism: nil,
            kdfType: nil,
            name: nil,
            orgIdentifier: nil,
            stamp: nil,
            userDecryptionOptions: nil,
            userId: ""
        ),
        settings: .init(environmentUrls: nil),
        tokens: .init(
            accessToken: "",
            refreshToken: ""
        )
    )
    let shortEmail = Account(
        profile: .init(
            avatarColor: nil,
            email: "a@gmail.com",
            emailVerified: nil,
            forcePasswordResetReason: nil,
            hasPremiumPersonally: nil,
            kdfIterations: nil,
            kdfMemory: nil,
            kdfParallelism: nil,
            kdfType: nil,
            name: nil,
            orgIdentifier: nil,
            stamp: nil,
            userDecryptionOptions: nil,
            userId: UUID().uuidString
        ),
        settings: .init(environmentUrls: nil),
        tokens: .init(
            accessToken: "",
            refreshToken: ""
        )
    )
    let shortName = Account(
        profile: .init(
            avatarColor: nil,
            email: "aj@gmail.com",
            emailVerified: nil,
            forcePasswordResetReason: nil,
            hasPremiumPersonally: nil,
            kdfIterations: nil,
            kdfMemory: nil,
            kdfParallelism: nil,
            kdfType: nil,
            name: "AJ",
            orgIdentifier: nil,
            stamp: nil,
            userDecryptionOptions: nil,
            userId: UUID().uuidString
        ),
        settings: .init(environmentUrls: nil),
        tokens: .init(
            accessToken: "",
            refreshToken: ""
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

    /// `getAccounts()` throws an error when the accounts are nil
    func test_getAccounts_empty() async throws {
        await assertAsyncThrows(error: StateServiceError.noAccounts) {
            _ = try await subject.getAccounts()
        }
    }

    /// `getAccounts()` returns all known accounts
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
                userId: "",
                userInitials: "  "
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

    /// `getActiveAccount()` returns a profile switcher item
    func test_getActiveAccount_empty() async throws {
        stateService.accounts = [
            anneAccount,
        ]

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getActiveAccount()
        }
    }

    /// `getActiveAccount()` returns an error when the active account is nil
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
