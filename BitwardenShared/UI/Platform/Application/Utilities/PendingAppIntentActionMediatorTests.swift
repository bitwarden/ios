import BitwardenKit
import BitwardenKitMocks
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
        stateService.pendingAppIntentActions = [.lockAll]

        await subject.executePendingAppIntentActions()

        XCTAssertTrue(authRepository.hasLockedAllVaults)
        XCTAssertTrue(authRepository.hasManuallyLocked)
        XCTAssertNil(delegate.onPendingAppIntentActionSuccessAction)
        XCTAssertNil(delegate.onPendingAppIntentActionSuccessData)
        XCTAssertEqual(stateService.pendingAppIntentActions, [])
    }

    /// `executePendingAppIntentActions()` with `.logOutAll` action calls the delegate informing that
    /// and updates the actions
    func test_executePendingAppIntentActions_logOutAll() async throws {
        stateService.pendingAppIntentActions = [.logOutAll]
        subject.setDelegate(delegate)

        await subject.executePendingAppIntentActions()

        XCTAssertEqual(delegate.onPendingAppIntentActionSuccessAction, .logOutAll)
        XCTAssertEqual(stateService.pendingAppIntentActions, [])
    }

    /// `executePendingAppIntentActions()` with `.logOutAll` action only updates the actions when there's no delegate.
    func test_executePendingAppIntentActions_logOutAllNoDelegate() async throws {
        stateService.pendingAppIntentActions = [.logOutAll]

        await subject.executePendingAppIntentActions()

        XCTAssertNil(delegate.onPendingAppIntentActionSuccessAction)
        XCTAssertEqual(stateService.pendingAppIntentActions, [])
    }

    /// `executePendingAppIntentActions()` with `.openGenerator` action calls the delegate informing that
    /// the generator screen needs to be opened.
    func test_executePendingAppIntentActions_openGenerator() async throws {
        stateService.activeAccount = .fixture()
        stateService.pendingAppIntentActions = [.openGenerator]
        subject.setDelegate(delegate)

        await subject.executePendingAppIntentActions()

        XCTAssertEqual(delegate.onPendingAppIntentActionSuccessAction, .openGenerator)
        XCTAssertEqual(stateService.pendingAppIntentActions, [])
    }

    /// `executePendingAppIntentActions()` with `.openGenerator` with no delegate
    /// doesn't inform the delegate to navigate to screen.
    func test_executePendingAppIntentActions_openGeneratorNoDelegate() async throws {
        stateService.activeAccount = .fixture()
        stateService.pendingAppIntentActions = [.openGenerator]

        await subject.executePendingAppIntentActions()

        XCTAssertNotEqual(delegate.onPendingAppIntentActionSuccessAction, .openGenerator)
        XCTAssertEqual(stateService.pendingAppIntentActions, [])
    }
}

class MockPendingAppIntentActionMediatorDelegate: PendingAppIntentActionMediatorDelegate {
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
