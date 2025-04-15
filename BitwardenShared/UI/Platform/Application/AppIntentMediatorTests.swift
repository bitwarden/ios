import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - AppIntentMediatorTests

class AppIntentMediatorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: AppIntentMediator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        configService = MockConfigService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        subject = DefaultAppIntentMediator(
            authRepository: authRepository,
            configService: configService,
            errorReporter: errorReporter,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        configService = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `canRunAppIntents()` returns `true` when it can run app intents.
    @MainActor
    func test_canRunAppIntents_true() async {
        configService.featureFlagsBool[.appIntents] = true
        let canRunAppIntents = await subject.canRunAppIntents()
        XCTAssertTrue(canRunAppIntents)
    }

    /// `canRunAppIntents()` returns `false` when it can't run app intents.
    @MainActor
    func test_canRunAppIntents_false() async {
        configService.featureFlagsBool[.appIntents] = false
        let canRunAppIntents = await subject.canRunAppIntents()
        XCTAssertFalse(canRunAppIntents)
    }

    /// `lockAllUsers()` locks all user vaults.
    func test_lockAllUsers() async throws {
        try await subject.lockAllUsers()
        XCTAssertTrue(authRepository.hasLockedAllVaults)
        XCTAssertTrue(authRepository.hasManuallyLocked)
    }

    /// `lockAllUsers()` throws when trying to lock all user vaults.
    func test_lockAllUsers_throws() async throws {
        authRepository.lockAllVaultsError = BitwardenTestError.example
        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.lockAllUsers()
        }
    }

    /// `logoutAllUsers()` logs out all accounts.
    func test_logoutAllUsers() async throws {
        stateService.accounts = [
            .fixture(profile: .fixture(userId: "1")),
            .fixture(profile: .fixture(userId: "2")),
            .fixture(profile: .fixture(userId: "3")),
        ]
        try await subject.logoutAllUsers()
        XCTAssertEqual(authRepository.logoutUserIds, ["1", "2", "3"])
    }

    /// `logoutAllUsers()` logs out some accounts because one of them throws.
    func test_logoutAllUsers_someThrows() async throws {
        stateService.accounts = [
            .fixture(profile: .fixture(userId: "1")),
            .fixture(profile: .fixture(userId: "2")),
            .fixture(profile: .fixture(userId: "3")),
        ]
        authRepository.logoutErrorByUserId = ["2": BitwardenTestError.example]
        try await subject.logoutAllUsers()
        XCTAssertEqual(authRepository.logoutUserIds, ["1", "3"])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `logoutAllUsers()` does nothing when there are no accounts.
    func test_logoutAllUsers_noAccounts() async throws {
        stateService.accounts = []
        try await subject.logoutAllUsers()
        XCTAssertTrue(authRepository.logoutUserIds.isEmpty)
        XCTAssertFalse(authRepository.logoutCalled)
    }

    /// `logoutAllUsers()` does nothing when getting accounts throw.
    func test_logoutAllUsers_throwGettingAccounts() async throws {
        stateService.accounts = nil
        try await subject.logoutAllUsers()
        XCTAssertTrue(authRepository.logoutUserIds.isEmpty)
        XCTAssertFalse(authRepository.logoutCalled)
    }
}
