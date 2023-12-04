import Combine
import XCTest

@testable import BitwardenShared

final class VaultTimeoutServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var cancellables: Set<AnyCancellable>!
    var stateService: MockStateService!
    var subject: DefaultVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cancellables = []
        stateService = MockStateService()
        subject = DefaultVaultTimeoutService(stateService: stateService)
    }

    override func tearDown() {
        super.tearDown()

        cancellables = nil
        subject = nil
        stateService = nil
    }

    /// Setting the timeoutStore should trigger the `shouldClearDecryptedDataPublisher` with the new values.
    func test_changeLockStore_locked_new() {
        let account = Account.fixtureAccountLogin()
        subject.activeAccountIdSubject.send(nil)

        subject.timeoutStore = [
            account.profile.userId: true,
        ]

        waitFor(subject.shouldClearDataSubject.value == true)
        XCTAssertTrue(subject.shouldClearDataSubject.value)
    }

    /// Setting the timeoutStore should trigger the `shouldClearDecryptedDataPublisher` with the new values.
    func test_changeLockStore_locked_current() {
        let account = Account.fixtureAccountLogin()
        let alternate = Account.fixture(profile: .fixture(userId: "123"))
        subject.timeoutStore = [
            account.profile.userId: false,
            alternate.profile.userId: false,
        ]
        subject.activeAccountIdSubject.send(account.profile.userId)

        subject.timeoutStore = [
            account.profile.userId: true,
            alternate.profile.userId: false,
        ]

        waitFor(subject.shouldClearDataSubject.value == true)
        XCTAssertTrue(subject.shouldClearDataSubject.value)
    }

    /// Setting the timeoutStore should trigger the `shouldClearDecryptedDataPublisher` with the new values.
    func test_changeLockStore_locked_alternate() {
        let account = Account.fixtureAccountLogin()
        let alternate = Account.fixture(profile: .fixture(userId: "123"))
        subject.timeoutStore = [
            account.profile.userId: false,
            alternate.profile.userId: false,
        ]
        subject.activeAccountIdSubject.send(account.profile.userId)

        subject.shouldClearDataSubject.send(true)
        subject.timeoutStore = [
            account.profile.userId: false,
            alternate.profile.userId: true,
        ]

        waitFor(subject.shouldClearDataSubject.value == false)
        XCTAssertFalse(subject.shouldClearDataSubject.value)
    }

    /// Setting the timeoutStore should trigger the `shouldClearDecryptedDataPublisher` with the new values.
    func test_changeLockStore_unlocked_existing() async {
        let account = Account.fixtureAccountLogin()
        subject.timeoutStore = [
            account.profile.userId: true,
        ]
        subject.activeAccountIdSubject.send(account.profile.userId)

        subject.timeoutStore = [
            account.profile.userId: false,
        ]
        waitFor(subject.shouldClearDataSubject.value == false)
        XCTAssertFalse(subject.shouldClearDataSubject.value)
    }

    /// Published changes to the active account should trigger the shouldClearDecryptedDataPublisher.
    func test_changeActiveAccount_nil() async {
        subject.activeAccountIdSubject.send(nil)

        waitFor(subject.shouldClearDataSubject.value == true)
        XCTAssertTrue(subject.shouldClearDataSubject.value)
    }

    /// Published changes to the active account should trigger the shouldClearDecryptedDataPublisher.
    func test_changeActiveAccount_change() async {
        let account = Account.fixtureAccountLogin()
        subject.activeAccountIdSubject.send(account.profile.userId)

        waitFor(subject.shouldClearDataSubject.value == true)
        XCTAssertTrue(subject.shouldClearDataSubject.value)
    }

    /// `isLocked(userId:)` should return true for a locked account.
    func test_isLocked_true() async {
        let account = Account.fixtureAccountLogin()
        subject.timeoutStore = [
            account.profile.userId: true,
        ]
        let isLocked = try? subject.isLocked(userId: account.profile.userId)
        XCTAssertTrue(isLocked!)
    }

    /// `isLocked(userId:)` should return false for an unlocked account.
    func test_isLocked_false() async {
        let account = Account.fixtureAccountLogin()
        subject.timeoutStore = [
            account.profile.userId: false,
        ]
        let isLocked = try? subject.isLocked(userId: account.profile.userId)
        XCTAssertFalse(isLocked!)
    }

    /// `isLocked(userId:)` should throw when no account is found.
    func test_isLocked_notFound() async {
        XCTAssertThrowsError(try subject.isLocked(userId: "123"))
    }

    /// `lockVault(userId: nil)` should lock the active account.
    func test_lock_nil_active() async {
        let account = Account.fixtureAccountLogin()
        stateService.activeAccount = account
        stateService.accounts = [account]
        subject.timeoutStore = [:]
        await subject.lockVault(userId: nil)
        XCTAssertEqual(
            [
                account.profile.userId: true,
            ],
            subject.timeoutStore
        )
    }

    /// `lockVault(userId: nil)` should do nothing for no active account.
    func test_lock_nil_noActive() async {
        stateService.activeAccount = nil
        stateService.accounts = []
        subject.timeoutStore = [:]
        await subject.lockVault(userId: nil)
        XCTAssertEqual([:], subject.timeoutStore)
    }

    /// `lockVault(userId:)` should lock an unlocked account.
    func test_lock_unlocked() async {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        subject.timeoutStore = [
            account.profile.userId: false,
        ]
        await subject.lockVault(userId: account.profile.userId)
        XCTAssertEqual(
            [
                account.profile.userId: true,
            ],
            subject.timeoutStore
        )
    }

    /// `lockVault(userId:)` preserves the lock status of a locked account.
    func test_lock_locked() async {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        subject.timeoutStore = [
            account.profile.userId: true,
        ]
        await subject.lockVault(userId: account.profile.userId)
        XCTAssertEqual(
            [
                account.profile.userId: true,
            ],
            subject.timeoutStore
        )
    }

    /// `lockVault(userId:)` should lock an unknown account.
    func test_lock_notFound() async {
        let account = Account.fixtureAccountLogin()
        subject.timeoutStore = [:]
        stateService.accounts = [account]
        await subject.lockVault(userId: account.profile.userId)
        XCTAssertEqual(
            [
                account.profile.userId: true,
            ],
            subject.timeoutStore
        )
    }

    /// `unlockVault(userId: nil)` should unock the active account.
    func test_unlock_nil_active() async {
        let account = Account.fixtureAccountLogin()
        stateService.activeAccount = account
        stateService.accounts = [account]
        subject.timeoutStore = [:]
        await subject.unlockVault(userId: nil)
        XCTAssertEqual(
            [
                account.profile.userId: false,
            ],
            subject.timeoutStore
        )
    }

    /// `unlockVault(userId: nil)` should do nothing for no active account.
    func test_unlock_nil_noActive() async {
        stateService.activeAccount = nil
        stateService.accounts = []
        subject.timeoutStore = [:]
        await subject.unlockVault(userId: nil)
        XCTAssertEqual([:], subject.timeoutStore)
    }

    /// `unlockVault(userId:)` preserves the unlocked status of an unlocked account.
    func test_unlock_unlocked() async {
        let account = Account.fixtureAccountLogin()
        subject.timeoutStore = [
            account.profile.userId: false,
        ]
        await subject.unlockVault(userId: account.profile.userId)
        XCTAssertEqual(
            [
                account.profile.userId: false,
            ],
            subject.timeoutStore
        )
    }

    /// `unlockVault(userId:)` should unlock a locked account.
    func test_unlock_locked() async {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        subject.timeoutStore = [
            account.profile.userId: true,
        ]
        await subject.unlockVault(userId: account.profile.userId)
        XCTAssertEqual(
            [
                account.profile.userId: false,
            ],
            subject.timeoutStore
        )
    }

    /// `unlockVault(userId:)` should unlock an unknown account.
    func test_unlock_notFound() async {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        subject.timeoutStore = [:]
        await subject.unlockVault(userId: account.profile.userId)
        XCTAssertEqual(
            [
                account.profile.userId: false,
            ],
            subject.timeoutStore
        )
    }

    /// `unlockVault(userId:)` should lock all other accounts.
    func test_unlock_locksAlternates() async {
        let account = Account.fixtureAccountLogin()
        let alternate = Account.fixture(profile: .fixture(userId: "123"))
        let secondAlternate = Account.fixture(profile: .fixture(userId: "312"))
        stateService.accounts = [
            account,
            alternate,
            secondAlternate,
        ]
        subject.timeoutStore = [
            account.profile.userId: true,
            alternate.profile.userId: false,
            secondAlternate.profile.userId: true,
        ]
        await subject.unlockVault(userId: account.profile.userId)
        XCTAssertEqual(
            [
                account.profile.userId: false,
                alternate.profile.userId: true,
                secondAlternate.profile.userId: true,
            ],
            subject.timeoutStore
        )
    }

    /// `remove(userId:)` should remove an unlocked account.
    func test_remove_unlocked() async {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        subject.timeoutStore = [
            account.profile.userId: false,
        ]
        await subject.remove(userId: account.profile.userId)
        XCTAssertTrue(subject.timeoutStore.isEmpty)
    }

    /// `remove(userId:)` should remove a locked account.
    func test_remove_locked() async {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        subject.timeoutStore = [
            account.profile.userId: true,
        ]
        await subject.remove(userId: account.profile.userId)
        XCTAssertTrue(subject.timeoutStore.isEmpty)
    }

    /// `remove(userId:)`preserves state when no account matches.
    func test_remove_notFound() async {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        subject.timeoutStore = [
            account.profile.userId: false,
        ]
        await subject.remove(userId: "123")
        XCTAssertEqual(
            [
                account.profile.userId: false,
            ],
            subject.timeoutStore
        )
    }
}
