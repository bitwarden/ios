import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - PendingAppIntentActionMediatorTests

class PendingAppIntentActionMediatorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var delegate: MockPendingAppIntentActionMediatorDelegate!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: PendingAppIntentActionMediator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        delegate = MockPendingAppIntentActionMediatorDelegate()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        subject = DefaultPendingAppIntentActionMediator(
            authRepository: authRepository,
            errorReporter: errorReporter,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        delegate = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `executePendingAppIntentActions()` with `.lockAll` action lock all vaults, calls the delegate informing that
    /// and updates the actions
    func test_executePendingAppIntentActions_lockAll() async throws {
        stateService.activeAccount = .fixture()
        stateService.pendingAppIntentActions = [.lockAll]
        subject.setDelegate(delegate)

        await subject.executePendingAppIntentActions()

        XCTAssertTrue(authRepository.hasLockedAllVaults)
        XCTAssertTrue(authRepository.hasManuallyLocked)
        XCTAssertEqual(delegate.onPendingAppIntentActionSuccessAction, .lockAll)
        let accountData = try XCTUnwrap(delegate.onPendingAppIntentActionSuccessData as? Account)
        XCTAssertEqual(accountData, stateService.activeAccount)
        XCTAssertEqual(stateService.pendingAppIntentActions, [])
    }

    /// `executePendingAppIntentActions()` with `.lockAll` doesn't lock all vaults when there is no active account.
    func test_executePendingAppIntentActions_lockAllAccountThrows() async throws {
        stateService.activeAccount = nil
        stateService.pendingAppIntentActions = [.lockAll]
        subject.setDelegate(delegate)

        await subject.executePendingAppIntentActions()

        XCTAssertFalse(authRepository.hasLockedAllVaults)
        XCTAssertFalse(authRepository.hasManuallyLocked)
    }

    /// `executePendingAppIntentActions()` with `.lockAll` doesn't lock all vaults
    /// because the `authRepository` throws when trying to do so.
    func test_executePendingAppIntentActions_lockAllThrows() async throws {
        stateService.activeAccount = .fixture()
        stateService.pendingAppIntentActions = [.lockAll]
        subject.setDelegate(delegate)
        authRepository.lockAllVaultsError = BitwardenTestError.example

        await subject.executePendingAppIntentActions()

        XCTAssertFalse(authRepository.hasLockedAllVaults)
        XCTAssertFalse(authRepository.hasManuallyLocked)
        XCTAssertNotEqual(delegate.onPendingAppIntentActionSuccessAction, .lockAll)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `executePendingAppIntentActions()` with `.lockAll` with no delegate locks all vaults but doens't inform
    /// to the delegate.
    func test_executePendingAppIntentActions_lockAllNoDelegate() async throws {
        stateService.activeAccount = .fixture()
        stateService.pendingAppIntentActions = [.lockAll, .lock("1")]

        await subject.executePendingAppIntentActions()

        XCTAssertTrue(authRepository.hasLockedAllVaults)
        XCTAssertTrue(authRepository.hasManuallyLocked)
        XCTAssertNil(delegate.onPendingAppIntentActionSuccessAction)
        XCTAssertNil(delegate.onPendingAppIntentActionSuccessData)
        XCTAssertEqual(stateService.pendingAppIntentActions, [])
    }

    /// `executePendingAppIntentActions()` with `.lock` actions locks the specified vaults,
    /// calls the delegate informing that and updates the actions
    func test_executePendingAppIntentActions_lock() async throws {
        stateService.activeAccount = .fixture()
        stateService.pendingAppIntentActions = [.lock("1"), .lock("2")]
        subject.setDelegate(delegate)

        await subject.executePendingAppIntentActions()

        XCTAssertEqual(authRepository.lockVaultUserIds, ["1", "2"])
        XCTAssertTrue(authRepository.hasManuallyLocked)
        XCTAssertEqual(delegate.onPendingAppIntentActionSuccessAction, .lock("1"))
        let accountData = try XCTUnwrap(delegate.onPendingAppIntentActionSuccessData as? Account)
        XCTAssertEqual(accountData, stateService.activeAccount)
        XCTAssertEqual(stateService.pendingAppIntentActions, [])
    }

    /// `executePendingAppIntentActions()` with `.lock` with no active account does nothing.
    func test_executePendingAppIntentActions_lockNoActiveAccount() async throws {
        stateService.activeAccount = nil
        stateService.pendingAppIntentActions = [.lock("1"), .lock("2")]
        subject.setDelegate(delegate)

        await subject.executePendingAppIntentActions()

        XCTAssertEqual(authRepository.lockVaultUserIds, [])
        XCTAssertFalse(authRepository.hasManuallyLocked)
    }

    /// `executePendingAppIntentActions()` with `.lock` with no delegate locks the vault but doens't
    /// inform to the delegate.
    func test_executePendingAppIntentActions_lockNoDelegate() async throws {
        stateService.activeAccount = .fixture()
        stateService.pendingAppIntentActions = [.lock("1"), .lock("2")]

        await subject.executePendingAppIntentActions()

        XCTAssertEqual(authRepository.lockVaultUserIds, ["1", "2"])
        XCTAssertTrue(authRepository.hasManuallyLocked)
        XCTAssertNil(delegate.onPendingAppIntentActionSuccessAction)
        XCTAssertNil(delegate.onPendingAppIntentActionSuccessData)
        XCTAssertEqual(stateService.pendingAppIntentActions, [])
    }
}

class MockPendingAppIntentActionMediatorDelegate: PendingAppIntentActionMediatorDelegate {
    // swiftlint:disable:previous type_name
    var onPendingAppIntentActionSuccessAction: PendingAppIntentAction?
    var onPendingAppIntentActionSuccessData: Any?

    func onPendingAppIntentActionSuccess(
        _ pendingAppIntentAction: PendingAppIntentAction,
        data: Any?
    ) async {
        onPendingAppIntentActionSuccessAction = pendingAppIntentAction
        onPendingAppIntentActionSuccessData = data
    }
}
