import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared

class RehydrationHelperTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var now: Date!
    var stateService: MockStateService!
    var subject: DefaultRehydrationHelper!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        errorReporter = MockErrorReporter()
        now = Date(year: 2024, month: 2, day: 14, hour: 8, minute: 0, second: 0)
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(now))
        subject = DefaultRehydrationHelper(
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider,
        )
    }

    override func tearDown() {
        super.tearDown()

        errorReporter = nil
        stateService = nil
        timeProvider = nil
        subject = nil
    }

    // MARK: Tests

    /// `addRehydratableTarget(_:)` adds a target.
    func test_addRehydratableTarget() async {
        let rehydratable = MockRehydratable()
        await subject.addRehydratableTarget(rehydratable)
        let lastTarget = await subject.getLastTargetState()
        XCTAssertEqual(lastTarget, rehydratable.rehydrationState)
    }

    /// `clearAppRehydrationState()` clears the state.
    func test_clearAppRehydrationState() async throws {
        stateService.activeAccount = Account.fixture()
        stateService.appRehydrationState["1"] = AppRehydrationState(
            target: .viewCipher(cipherId: "1"), expirationTime: now,
        )
        try await subject.clearAppRehydrationState()
        XCTAssertTrue(stateService.appRehydrationState.isEmpty)
    }

    /// `clearAppRehydrationState()` throws when inner throws.
    func test_clearAppRehydrationState_throws() async throws {
        stateService.activeAccount = nil
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.clearAppRehydrationState()
        }
    }

    /// `getLastTargetState()` returns the last target state.
    func test_getLastTargetState() async throws {
        let rehydratable1 = MockRehydratable(RehydrationState(target: .viewCipher(cipherId: "1")))
        await subject.addRehydratableTarget(rehydratable1)

        let lastTarget = await subject.getLastTargetState()
        XCTAssertEqual(lastTarget?.target, .viewCipher(cipherId: "1"))
    }

    /// `getLastTargetState()` returns the last target state when one of the weak references are gone.
    func test_getLastTargetState_whenOneWeakReferenceGone() async throws {
        let rehydratable1: Rehydratable? = MockRehydratable(RehydrationState(target: .viewCipher(cipherId: "1")))
        var rehydratable2: Rehydratable? = MockRehydratable(RehydrationState(target: .viewCipher(cipherId: "2")))
        await subject.addRehydratableTarget(rehydratable1!)
        await subject.addRehydratableTarget(rehydratable2!)

        rehydratable2 = nil

        let lastTarget = await subject.getLastTargetState()
        XCTAssertEqual(lastTarget?.target, .viewCipher(cipherId: "1"))
    }

    /// `getLastTargetState()` returns nil when all weak references are gone.
    func test_getLastTargetState_nilNoReferences() async throws {
        var rehydratable1: Rehydratable? = MockRehydratable(RehydrationState(target: .viewCipher(cipherId: "1")))
        var rehydratable2: Rehydratable? = MockRehydratable(RehydrationState(target: .viewCipher(cipherId: "2")))
        await subject.addRehydratableTarget(rehydratable1!)
        await subject.addRehydratableTarget(rehydratable2!)

        rehydratable1 = nil
        rehydratable2 = nil

        let lastTarget = await subject.getLastTargetState()
        XCTAssertNil(lastTarget)
    }

    /// `getSavedRehydratableTarget()` returns the saved rehydratable target when it exists
    /// and its expiration time has not passed.
    func test_getSavedRehydratableTarget() async throws {
        stateService.activeAccount = Account.fixture()
        stateService.appRehydrationState["1"] = AppRehydrationState(
            target: .viewCipher(cipherId: "1"), expirationTime: now.addingTimeInterval(10),
        )
        let target = try await subject.getSavedRehydratableTarget()
        XCTAssertEqual(target, .viewCipher(cipherId: "1"))
    }

    /// `getSavedRehydratableTarget()` returns nil when not found.
    func test_getSavedRehydratableTarget_notFound() async throws {
        stateService.activeAccount = Account.fixture()
        let target = try await subject.getSavedRehydratableTarget()
        XCTAssertNil(target)
    }

    /// `getSavedRehydratableTarget()` returns nil when not found for active user.
    func test_getSavedRehydratableTarget_notFoundForActiveUser() async throws {
        stateService.activeAccount = Account.fixture()
        stateService.appRehydrationState["not active"] = AppRehydrationState(
            target: .viewCipher(cipherId: "not active"), expirationTime: now.addingTimeInterval(10),
        )
        let target = try await subject.getSavedRehydratableTarget()
        XCTAssertNil(target)
    }

    /// `getSavedRehydratableTarget()` returns nil expiration time passed and clears its state.
    func test_getSavedRehydratableTarget_expired() async throws {
        stateService.activeAccount = Account.fixture()
        stateService.appRehydrationState["1"] = AppRehydrationState(
            target: .viewCipher(cipherId: "1"), expirationTime: now.addingTimeInterval(-2),
        )
        let target = try await subject.getSavedRehydratableTarget()
        XCTAssertNil(target)
        XCTAssertTrue(stateService.appRehydrationState.isEmpty)
    }

    /// `getSavedRehydratableTarget()` throws on no active accounts.
    func test_getSavedRehydratableTarget_throwsNoActiveAccounts() async throws {
        stateService.activeAccount = nil
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getSavedRehydratableTarget()
        }
    }

    /// `getSavedRehydratableTarget()` throws on clearing app rehydration state.
    func test_getSavedRehydratableTarget_throwsClearingAppRehydrationState() async throws {
        stateService.activeAccount = Account.fixture()
        stateService.appRehydrationState["1"] = AppRehydrationState(
            target: .viewCipher(cipherId: "1"), expirationTime: now.addingTimeInterval(-2),
        )
        stateService.setAppRehydrationStateError = BitwardenTestError.example
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.getSavedRehydratableTarget()
        }
    }

    /// `saveRehydrationStateIfNeeded()` saves the last target state.
    func test_saveRehydrationStateIfNeeded() async throws {
        stateService.activeAccount = Account.fixture()
        let rehydratable1 = MockRehydratable(RehydrationState(target: .viewCipher(cipherId: "1")))
        await subject.addRehydratableTarget(rehydratable1)

        await subject.saveRehydrationStateIfNeeded()
        let appRehydrationState = try XCTUnwrap(stateService.appRehydrationState["1"])
        XCTAssertEqual(appRehydrationState.target, .viewCipher(cipherId: "1"))
        XCTAssertEqual(appRehydrationState.expirationTime, now.addingTimeInterval(300))
    }

    /// `saveRehydrationStateIfNeeded()`  doesn't save the last target state when there's no target state.
    func test_saveRehydrationStateIfNeeded_nil() async throws {
        stateService.activeAccount = Account.fixture()
        var rehydratable1: Rehydratable? = MockRehydratable(RehydrationState(target: .viewCipher(cipherId: "1")))
        await subject.addRehydratableTarget(rehydratable1!)

        rehydratable1 = nil

        await subject.saveRehydrationStateIfNeeded()
        XCTAssertTrue(stateService.appRehydrationState.isEmpty)
    }

    /// `saveRehydrationStateIfNeeded()`  throws when there's no active account.
    func test_saveRehydrationStateIfNeeded_throwsNoAccount() async throws {
        stateService.activeAccount = nil
        let rehydratable1 = MockRehydratable(RehydrationState(target: .viewCipher(cipherId: "1")))
        await subject.addRehydratableTarget(rehydratable1)
        await subject.saveRehydrationStateIfNeeded()
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }
}

// MARK: - MockRehydratable

class MockRehydratable: Rehydratable {
    var rehydrationState: RehydrationState?

    init(_ rehydrationState: RehydrationState? = nil) {
        self.rehydrationState = rehydrationState
    }
}

// MARK: - WeakWrapper

class WeakWrapperTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(value:)` wraps the object value passed.
    func test_init_wrapsObject() throws {
        let object = MockRehydratable(RehydrationState(target: .viewCipher(cipherId: "1")))
        let wrapper = WeakWrapper(value: object)
        let val = try XCTUnwrap(wrapper.weakValue as? Rehydratable)
        XCTAssertEqual(val.rehydrationState?.target, .viewCipher(cipherId: "1"))
    }

    /// `getter:weakValue` returns `nil` when reference is gone.
    func test_weakValue_nil() throws {
        var object: Rehydratable? = MockRehydratable(RehydrationState(target: .viewCipher(cipherId: "1")))
        let wrapper = WeakWrapper(value: object!)
        object = nil
        XCTAssertNil(wrapper.weakValue)
    }
}
