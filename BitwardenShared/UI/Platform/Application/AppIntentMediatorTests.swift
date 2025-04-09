import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - AppIntentMediatorTests

class AppIntentMediatorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var configService: MockConfigService!
    var subject: AppIntentMediator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        configService = MockConfigService()
        subject = DefaultAppIntentMediator(authRepository: authRepository, configService: configService)
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        configService = nil
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
}
