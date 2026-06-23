import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - FillAssistRepositoryTests

@MainActor
class FillAssistRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var configService: MockConfigService!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var fillAssistAPIService: MockFillAssistAPIService!
    var stateService: MockStateService!
    var subject: DefaultFillAssistRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        configService = MockConfigService()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        fillAssistAPIService = MockFillAssistAPIService()
        stateService = MockStateService()

        subject = DefaultFillAssistRepository(
            appSettingsStore: appSettingsStore,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            fillAssistAPIService: fillAssistAPIService,
            stateService: stateService,
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()

        appSettingsStore = nil
        configService = nil
        environmentService = nil
        errorReporter = nil
        fillAssistAPIService = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests - syncFillAssistRules

    /// `syncFillAssistRules()` makes no network calls when the feature flag is disabled.
    func test_syncFillAssistRules_featureFlagDisabled() async {
        configService.featureFlagsBool[.fillAssistTargetingRules] = false
        stateService.activeAccount = .fixture()

        await subject.syncFillAssistRules()

        XCTAssertFalse(fillAssistAPIService.getManifestCalled)
    }

    /// `syncFillAssistRules()` makes no network calls when the update interval has not elapsed.
    func test_syncFillAssistRules_withinUpdateInterval() async {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true
        stateService.activeAccount = .fixture()
        appSettingsStore.fillAssistLastFetchTimestampByUserId["1"] = Date()

        await subject.syncFillAssistRules()

        XCTAssertFalse(fillAssistAPIService.getManifestCalled)
    }

    /// `syncFillAssistRules()` skips download and updates the timestamp when cid and source URL are unchanged.
    func test_syncFillAssistRules_cidUnchanged_updatesTimestampOnly() async throws {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true
        stateService.activeAccount = .fixture()
        let sourceUrl = environmentService.fillAssistRulesURL.absoluteString

        appSettingsStore.fillAssistCachedDataByUserId["1"] = FillAssistCachedData(
            cid: "sha256:abc123",
            rules: [:],
            sourceUrl: sourceUrl,
        )
        fillAssistAPIService.getManifestReturnValue = try makeManifest(cid: "sha256:abc123")

        await subject.syncFillAssistRules()

        XCTAssertTrue(fillAssistAPIService.getManifestCalled)
        XCTAssertFalse(fillAssistAPIService.getFormsMapCalled)
        XCTAssertNotNil(appSettingsStore.fillAssistLastFetchTimestampByUserId["1"])
    }

    /// `syncFillAssistRules()` downloads, parses, and caches rules when cid changes.
    func test_syncFillAssistRules_cidChanged_downloadsAndCaches() async throws {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true
        stateService.activeAccount = .fixture()

        fillAssistAPIService.getManifestReturnValue = try makeManifest(cid: "sha256:newcid")
        fillAssistAPIService.getFormsMapReturnValue = try makeFormsMap()

        await subject.syncFillAssistRules()

        XCTAssertTrue(fillAssistAPIService.getManifestCalled)
        XCTAssertTrue(fillAssistAPIService.getFormsMapCalled)
        XCTAssertEqual(fillAssistAPIService.getFormsMapReceivedFilename, "forms.v1.json")
        let cached = appSettingsStore.fillAssistCachedDataByUserId["1"]
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.cid, "sha256:newcid")
        XCTAssertNotNil(appSettingsStore.fillAssistLastFetchTimestampByUserId["1"])
    }

    /// `syncFillAssistRules()` skips storing when the schema major version is unsupported.
    func test_syncFillAssistRules_unsupportedSchema_skipsCache() async throws {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true
        stateService.activeAccount = .fixture()

        fillAssistAPIService.getManifestReturnValue = try makeManifest(cid: "sha256:newcid")
        fillAssistAPIService.getFormsMapReturnValue = try makeFormsMap(schemaVersion: "2.0.0")

        await subject.syncFillAssistRules()

        XCTAssertNil(appSettingsStore.fillAssistCachedDataByUserId["1"])
        XCTAssertNotNil(appSettingsStore.fillAssistLastFetchTimestampByUserId["1"])
    }

    /// `syncFillAssistRules()` logs errors but does not rethrow them.
    func test_syncFillAssistRules_failure_logsError() async {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true
        stateService.activeAccount = .fixture()
        fillAssistAPIService.getManifestThrowableError = URLError(.notConnectedToInternet)

        await subject.syncFillAssistRules()

        XCTAssertEqual(errorReporter.errors.count, 1)
        XCTAssertNil(appSettingsStore.fillAssistCachedDataByUserId["1"])
    }

    // MARK: Tests - fillAssistRules(for:)

    /// `fillAssistRules(for:)` returns rules for a cached hostname.
    func test_fillAssistRules_returnsRulesForHostname() async {
        stateService.activeAccount = .fixture()
        let hostRules = FillAssistHostRules(fields: ["username": []])
        appSettingsStore.fillAssistCachedDataByUserId["1"] = FillAssistCachedData(
            cid: "sha256:abc",
            rules: ["example.com": hostRules],
            sourceUrl: "https://example.com",
        )

        let result = await subject.fillAssistRules(for: "example.com")

        XCTAssertEqual(result, hostRules)
    }

    /// `fillAssistRules(for:)` returns nil for an unknown hostname.
    func test_fillAssistRules_returnsNilForUnknownHostname() async {
        stateService.activeAccount = .fixture()
        appSettingsStore.fillAssistCachedDataByUserId["1"] = FillAssistCachedData(
            cid: "sha256:abc",
            rules: [:],
            sourceUrl: "https://example.com",
        )

        let result = await subject.fillAssistRules(for: "unknown.com")

        XCTAssertNil(result)
    }

    // MARK: Tests - clearFillAssistRules()

    /// `clearFillAssistRules()` removes cached data for the active account.
    func test_clearFillAssistRules_removesCachedData() async throws {
        stateService.activeAccount = .fixture()
        appSettingsStore.fillAssistCachedDataByUserId["1"] = FillAssistCachedData(
            cid: "sha256:abc",
            rules: [:],
            sourceUrl: "https://example.com",
        )

        try await subject.clearFillAssistRules()

        XCTAssertNil(appSettingsStore.fillAssistCachedDataByUserId["1"])
    }

    // MARK: Helpers

    private func makeManifest(cid: String) throws -> FillAssistManifestResponseModel {
        let json = """
        {
            "buildId": "v1",
            "gitSha": "abc",
            "maps": { "forms": { "v1": {
                "cid": "\(cid)",
                "filename": "forms.v1.json",
                "schema": "forms.v1.schema.json"
            }}},
            "timestamp": "2026-06-11T14:29:32.184Z"
        }
        """
        return try JSONDecoder.pascalOrSnakeCaseDecoder.decode(
            FillAssistManifestResponseModel.self,
            from: Data(json.utf8),
        )
    }

    private func makeFormsMap(schemaVersion: String = "1.0.0") throws -> FormsMapResponseModel {
        let json = """
        {
            "schemaVersion": "\(schemaVersion)",
            "hosts": {
                "example.com": {
                    "forms": [{ "category": "account-login", "fields": { "username": ["input#user"] } }]
                }
            }
        }
        """
        return try JSONDecoder.pascalOrSnakeCaseDecoder.decode(
            FormsMapResponseModel.self,
            from: Data(json.utf8),
        )
    }
}
