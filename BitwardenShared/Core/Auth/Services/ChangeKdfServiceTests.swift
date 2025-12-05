import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

@MainActor
class ChangeKdfServiceTests: BitwardenTestCase {
    // MARK: Properties

    var accountAPIService: AccountAPIService!
    var client: MockHTTPClient!
    var clientService: MockClientService!
    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var flightRecorder: MockFlightRecorder!
    var stateService: MockStateService!
    var subject: ChangeKdfService!
    var syncService: MockSyncService!

    let accountIterationsBelowMin = Account.fixture(profile: .fixture(kdfIterations: 599_999, kdfType: .pbkdf2sha256))
    let accountIterationsAtMin = Account.fixture(profile: .fixture(kdfIterations: 600_000, kdfType: .pbkdf2sha256))
    let accountIterationsAboveMin = Account.fixture(profile: .fixture(kdfIterations: 600_001, kdfType: .pbkdf2sha256))

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        accountAPIService = APIService(client: client)
        clientService = MockClientService()
        configService = MockConfigService()
        errorReporter = MockErrorReporter()
        flightRecorder = MockFlightRecorder()
        stateService = MockStateService()
        syncService = MockSyncService()

        subject = DefaultChangeKdfService(
            accountAPIService: accountAPIService,
            clientService: clientService,
            configService: configService,
            errorReporter: errorReporter,
            flightRecorder: flightRecorder,
            stateService: stateService,
            syncService: syncService,
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()

        accountAPIService = nil
        client = nil
        clientService = nil
        configService = nil
        errorReporter = nil
        flightRecorder = nil
        stateService = nil
        subject = nil
        syncService = nil
    }

    // MARK: Tests

    /// `needsKdfUpdateToMinimums()` returns false if the account needs an update, but after syncing
    /// the account has already been updated.
    func test_needsKdfUpdateToMinimums_false_afterSync() async {
        configService.featureFlagsBool[.forceUpdateKdfSettings] = true
        stateService.activeAccount = accountIterationsBelowMin
        syncService.fetchSyncHandler = { [weak self] in
            guard let self else { return }
            stateService.activeAccount = accountIterationsAboveMin
        }

        let needsUpdate = await subject.needsKdfUpdateToMinimums()
        XCTAssertFalse(needsUpdate)
        XCTAssertTrue(syncService.didFetchSync)
        XCTAssertEqual(syncService.fetchSyncForceSync, false)
    }

    /// `needsKdfUpdateToMinimums()` returns false and logs an error if one occurs.
    func test_needsKdfUpdateToMinimums_false_error() async {
        configService.featureFlagsBool[.forceUpdateKdfSettings] = true

        let needsUpdate = await subject.needsKdfUpdateToMinimums()
        XCTAssertFalse(needsUpdate)
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `needsKdfUpdateToMinimums()` returns false if the feature flag is off.
    func test_needsKdfUpdateToMinimums_false_featureFlagOff() async {
        configService.featureFlagsBool[.forceUpdateKdfSettings] = false
        stateService.activeAccount = accountIterationsBelowMin

        let needsUpdate = await subject.needsKdfUpdateToMinimums()
        XCTAssertFalse(needsUpdate)
    }

    /// `needsKdfUpdateToMinimums()` returns false if the account doesn't have a master password.
    func test_needsKdfUpdateToMinimums_false_noMasterPassword() async {
        configService.featureFlagsBool[.forceUpdateKdfSettings] = true
        stateService.activeAccount = accountIterationsBelowMin
        stateService.userHasMasterPassword["1"] = false

        let needsUpdate = await subject.needsKdfUpdateToMinimums()
        XCTAssertFalse(needsUpdate)
    }

    /// `needsKdfUpdateToMinimums()` returns false if the account doesn't use PBKDF2.
    func test_needsKdfUpdateToMinimums_false_notUsingPbkdf2() async {
        configService.featureFlagsBool[.forceUpdateKdfSettings] = true
        stateService.activeAccount = .fixture(profile: .fixture(kdfIterations: 1, kdfType: .argon2id))

        let needsUpdate = await subject.needsKdfUpdateToMinimums()
        XCTAssertFalse(needsUpdate)
    }

    /// `needsKdfUpdateToMinimums()` returns false if the account uses PBKDF2 with iterations above
    /// the minimum.
    func test_needsKdfUpdateToMinimums_false_iterationsAboveMinimum() async {
        configService.featureFlagsBool[.forceUpdateKdfSettings] = true
        stateService.activeAccount = accountIterationsAboveMin

        let needsUpdate = await subject.needsKdfUpdateToMinimums()
        XCTAssertFalse(needsUpdate)
    }

    /// `needsKdfUpdateToMinimums()` returns false if the account uses PBKDF2 with iterations at the
    /// minimum.
    func test_needsKdfUpdateToMinimums_false_iterationsAtMinimum() async {
        configService.featureFlagsBool[.forceUpdateKdfSettings] = true
        stateService.activeAccount = accountIterationsAtMin

        let needsUpdate = await subject.needsKdfUpdateToMinimums()
        XCTAssertFalse(needsUpdate)
    }

    /// `needsKdfUpdateToMinimums()` returns true if the feature flag is on and the account uses
    /// PBKDF2 with iterations below the minimum.
    func test_needsKdfUpdateToMinimums_true() async {
        configService.featureFlagsBool[.forceUpdateKdfSettings] = true
        stateService.activeAccount = accountIterationsBelowMin

        let needsUpdate = await subject.needsKdfUpdateToMinimums()
        XCTAssertTrue(needsUpdate)
        XCTAssertTrue(syncService.didFetchSync)
        XCTAssertEqual(syncService.fetchSyncForceSync, false)
    }

    /// `updateKdfToMinimums(password:)` updates the user's KDF settings.
    func test_updateKdfToMinimums() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)
        configService.featureFlagsBool[.forceUpdateKdfSettings] = true
        stateService.activeAccount = accountIterationsBelowMin

        try await subject.updateKdfToMinimums(password: "password123!")

        XCTAssertEqual(clientService.mockCrypto.makeUpdateKdfKdf, .pbkdf2(iterations: 600_000))
        XCTAssertEqual(clientService.mockCrypto.makeUpdateKdfPassword, "password123!")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/accounts/kdf")
    }

    /// `updateKdfToMinimums(password:)` throws an error if there's no active account.
    func test_updateKdfToMinimums_error_noActiveAccount() async throws {
        configService.featureFlagsBool[.forceUpdateKdfSettings] = true
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.updateKdfToMinimums(password: "password123!")
        }
    }

    /// `updateKdfToMinimums(password:)` logs an error and throws it if updating the KDF fails.
    func test_updateKdfToMinimums_error_updateKdfError() async throws {
        clientService.mockCrypto.makeUpdateKdfResult = .failure(BitwardenTestError.example)
        configService.featureFlagsBool[.forceUpdateKdfSettings] = true
        stateService.activeAccount = accountIterationsBelowMin

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.updateKdfToMinimums(password: "password123!")
        }

        let nsError = try XCTUnwrap(errorReporter.errors.last as? NSError)
        XCTAssertEqual(nsError.domain, "General Error: Force Update KDF Error")
        XCTAssertEqual(
            nsError.userInfo["ErrorMessage"] as? String,
            """
            Unable to update KDF settings \
            (KdfConfig(kdfType: BitwardenShared.KdfType.pbkdf2sha256, iterations: 599999, \
            memory: nil, parallelism: nil)
            """,
        )
        XCTAssertTrue(client.requests.isEmpty)
    }

    /// `updateKdfToMinimums(password:)` doesn't updates the user's KDF settings if the feature flag is off.
    func test_updateKdfToMinimums_featureFlagOff() async throws {
        configService.featureFlagsBool[.forceUpdateKdfSettings] = false
        stateService.activeAccount = accountIterationsBelowMin

        try await subject.updateKdfToMinimums(password: "password123!")

        XCTAssertNil(clientService.mockCrypto.makeUpdateKdfKdf)
        XCTAssertTrue(client.requests.isEmpty)
    }

    /// `updateKdfToMinimumsIfNeeded(password:)` doesn't update the user's KDF settings if the
    /// iterations are above the minimum.
    func test_updateKdfToMinimumsIfNeeded_iterationsAboveMinimum() async throws {
        configService.featureFlagsBool[.forceUpdateKdfSettings] = true
        stateService.activeAccount = accountIterationsAboveMin

        try await subject.updateKdfToMinimumsIfNeeded(password: "password123!")

        XCTAssertNil(clientService.mockCrypto.makeUpdateKdfKdf)
        XCTAssertTrue(client.requests.isEmpty)
    }

    /// `updateKdfToMinimumsIfNeeded(password:)` updates the user's KDF settings if the
    /// iterations are below the minimum.
    func test_updateKdfToMinimumsIfNeeded_iterationsBelowMinimum() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)
        configService.featureFlagsBool[.forceUpdateKdfSettings] = true
        stateService.activeAccount = accountIterationsBelowMin

        try await subject.updateKdfToMinimumsIfNeeded(password: "password123!")

        XCTAssertEqual(clientService.mockCrypto.makeUpdateKdfKdf, .pbkdf2(iterations: 600_000))
        XCTAssertEqual(clientService.mockCrypto.makeUpdateKdfPassword, "password123!")
        XCTAssertEqual(stateService.setAccountKdfByUserId["1"], KdfConfig.defaultKdfConfig)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/accounts/kdf")
        XCTAssertEqual(flightRecorder.logMessages, ["[Auth] Upgraded user's KDF to minimums"])
    }
}
