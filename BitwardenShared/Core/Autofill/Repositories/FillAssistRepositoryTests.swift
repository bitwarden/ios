import BitwardenKit
import BitwardenKitMocks
import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - FillAssistRepositoryTests

@MainActor
struct FillAssistRepositoryTests {
    // MARK: Properties

    let appSettingsStore: MockAppSettingsStore
    let configService: MockConfigService
    let environmentService: MockEnvironmentService
    let errorReporter: MockErrorReporter
    let fillAssistAPIService: MockFillAssistAPIService
    let stateService: MockStateService
    let subject: DefaultFillAssistRepository
    let timeProvider: MockTimeProvider

    // MARK: Initialization

    init() {
        appSettingsStore = MockAppSettingsStore()
        configService = MockConfigService()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        fillAssistAPIService = MockFillAssistAPIService()
        stateService = MockStateService()
        stateService.activeAccount = .fixture()
        timeProvider = MockTimeProvider(.currentTime)

        subject = DefaultFillAssistRepository(
            appSettingsStore: appSettingsStore,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            fillAssistAPIService: fillAssistAPIService,
            stateService: stateService,
            timeProvider: timeProvider,
        )
    }

    // MARK: Tests - syncRules

    /// `syncRules()` makes no network calls when the feature flag is disabled.
    @Test
    func syncRules_featureFlagDisabled() async {
        configService.featureFlagsBool[.fillAssistTargetingRules] = false

        await subject.syncRules()

        #expect(!fillAssistAPIService.getManifestCalled)
    }

    /// `syncRules()` makes no network calls when the update interval has not elapsed.
    @Test
    func syncRules_withinUpdateInterval() async {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true
        appSettingsStore.fillAssistLastFetchTimestampByUserId["1"] = timeProvider.presentTime

        await subject.syncRules()

        #expect(!fillAssistAPIService.getManifestCalled)
    }

    /// `syncRules()` skips download and updates the timestamp when cid and source URL are unchanged.
    @Test
    func syncRules_cidUnchanged_updatesTimestampOnly() async {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true
        let sourceUrl = environmentService.fillAssistRulesURL.absoluteString

        appSettingsStore.fillAssistCachedDataByUserId["1"] = FillAssistCachedData(
            cid: "sha256:abc123",
            rules: [:],
            sourceUrl: sourceUrl,
        )
        fillAssistAPIService.getManifestReturnValue = makeManifest(cid: "sha256:abc123")

        await subject.syncRules()

        #expect(fillAssistAPIService.getManifestCalled)
        #expect(!fillAssistAPIService.getFormsMapCalled)
        #expect(appSettingsStore.fillAssistLastFetchTimestampByUserId["1"] != nil)
    }

    /// `syncRules()` downloads, parses, and caches rules when cid changes.
    @Test
    func syncRules_cidChanged_downloadsAndCaches() async throws {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true

        fillAssistAPIService.getManifestReturnValue = makeManifest(cid: "sha256:newcid")
        fillAssistAPIService.getFormsMapReturnValue = try makeFormsMap()

        await subject.syncRules()

        #expect(fillAssistAPIService.getManifestCalled)
        #expect(fillAssistAPIService.getFormsMapCalled)
        #expect(fillAssistAPIService.getFormsMapReceivedFilename == "forms.v1.json")
        let cached = appSettingsStore.fillAssistCachedDataByUserId["1"]
        #expect(cached != nil)
        #expect(cached?.cid == "sha256:newcid")
        #expect(appSettingsStore.fillAssistLastFetchTimestampByUserId["1"] != nil)
    }

    /// `syncRules()` skips storing when the schema major version is unsupported.
    @Test
    func syncRules_unsupportedSchema_skipsCache() async throws {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true

        fillAssistAPIService.getManifestReturnValue = makeManifest(cid: "sha256:newcid")
        fillAssistAPIService.getFormsMapReturnValue = try makeFormsMap(schemaVersion: "2.0.0")

        await subject.syncRules()

        #expect(appSettingsStore.fillAssistCachedDataByUserId["1"] == nil)
        #expect(appSettingsStore.fillAssistLastFetchTimestampByUserId["1"] != nil)
    }

    /// `syncRules()` parses CSS selectors into `FillAssistFieldAttributes` (selector pooling).
    @Test
    func syncRules_parsesSelectorsIntoRules() async throws {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true

        fillAssistAPIService.getManifestReturnValue = makeManifest(cid: "sha256:newcid")
        fillAssistAPIService.getFormsMapReturnValue = try makeFormsMap()

        await subject.syncRules()

        let hostRules = appSettingsStore.fillAssistCachedDataByUserId["1"]?.rules["example.com"]
        let usernameAttrs = try #require(hostRules?.fields["username"]?.first)
        #expect(usernameAttrs.id == "user")
        #expect(usernameAttrs.tagName == "input")
    }

    /// `syncRules()` pools selectors from multiple pathname entries into a single host entry.
    @Test
    func syncRules_poolsSelectorsAcrossPathnames() async throws {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true

        fillAssistAPIService.getManifestReturnValue = makeManifest(cid: "sha256:newcid")
        fillAssistAPIService.getFormsMapReturnValue = try makeFormsMapWithPathnames()

        await subject.syncRules()

        let usernameAttrs = appSettingsStore.fillAssistCachedDataByUserId["1"]?
            .rules["example.com"]?.fields["username"]
        let count = try #require(usernameAttrs).count
        #expect(count == 2)
    }

    /// `syncRules()` produces no rules entry when a host has no parseable selectors.
    @Test
    func syncRules_emptyPooled_excludesHost() async throws {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true

        fillAssistAPIService.getManifestReturnValue = makeManifest(cid: "sha256:newcid")
        // Shadow DOM selectors are excluded by the parser → pooled stays empty.
        fillAssistAPIService.getFormsMapReturnValue = try makeFormsMap(
            usernameSelector: "div#app >>> input#user",
        )

        await subject.syncRules()

        let rules = appSettingsStore.fillAssistCachedDataByUserId["1"]?.rules
        #expect(rules?["example.com"] == nil)
    }

    /// `syncRules()` returns an empty rules dict when the forms map has no hosts.
    @Test
    func syncRules_noHosts_emptyRules() async throws {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true

        fillAssistAPIService.getManifestReturnValue = makeManifest(cid: "sha256:newcid")
        fillAssistAPIService.getFormsMapReturnValue = try makeFormsMap(hosts: [:])

        await subject.syncRules()

        let rules = appSettingsStore.fillAssistCachedDataByUserId["1"]?.rules
        #expect(rules?.isEmpty == true)
    }

    /// `syncRules()` caches rules for multiple hosts independently.
    @Test
    func syncRules_multipleHosts_allCached() async throws {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true

        fillAssistAPIService.getManifestReturnValue = makeManifest(cid: "sha256:newcid")
        fillAssistAPIService.getFormsMapReturnValue = try makeFormsMap(
            hosts: ["example.com": "input#user1", "other.com": "input#user2"],
        )

        await subject.syncRules()

        let rules = appSettingsStore.fillAssistCachedDataByUserId["1"]?.rules
        #expect(rules?["example.com"] != nil)
        #expect(rules?["other.com"] != nil)
        #expect(rules?.count == 2)
    }

    /// `syncRules()` logs errors but does not rethrow them.
    @Test
    func syncRules_failure_logsError() async {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true
        fillAssistAPIService.getManifestThrowableError = URLError(.notConnectedToInternet)

        await subject.syncRules()

        #expect(errorReporter.errors.count == 1)
        #expect(appSettingsStore.fillAssistCachedDataByUserId["1"] == nil)
    }

    // MARK: Tests - rules(for:)

    /// `rules(for:)` returns cached rules for a known hostname.
    @Test
    func rules_returnsRulesForHostname() async {
        let hostRules = FillAssistHostRules(fields: ["username": []])
        appSettingsStore.fillAssistCachedDataByUserId["1"] = FillAssistCachedData(
            cid: "sha256:abc",
            rules: ["example.com": hostRules],
            sourceUrl: "https://example.com",
        )

        let result = await subject.rules(for: "example.com")

        #expect(result == hostRules)
    }

    /// `rules(for:)` returns `nil` for an unknown hostname.
    @Test
    func rules_returnsNilForUnknownHostname() async {
        appSettingsStore.fillAssistCachedDataByUserId["1"] = FillAssistCachedData(
            cid: "sha256:abc",
            rules: [:],
            sourceUrl: "https://example.com",
        )

        let result = await subject.rules(for: "unknown.com")

        #expect(result == nil)
    }

    // MARK: Tests - clearRules()

    /// `clearRules()` removes cached data for the active account.
    @Test
    func clearRules_removesCachedData() async throws {
        appSettingsStore.fillAssistCachedDataByUserId["1"] = FillAssistCachedData(
            cid: "sha256:abc",
            rules: [:],
            sourceUrl: "https://example.com",
        )

        try await subject.clearRules()

        #expect(appSettingsStore.fillAssistCachedDataByUserId["1"] == nil)
    }

    // MARK: Tests - FormsMapSelector.attributes

    /// `FormsMapSelector.attributes` parses a single CSS selector.
    @Test
    func formsMapSelector_single_returnsAttributes() {
        let attrs = FormsMapSelector.single("input#user").attributes
        #expect(attrs.count == 1)
        #expect(attrs.first?.id == "user")
        #expect(attrs.first?.tagName == "input")
    }

    /// `FormsMapSelector.attributes` parses each selector in a sequence.
    @Test
    func formsMapSelector_sequence_returnsAttributesForEach() {
        let attrs = FormsMapSelector.sequence(["input#user", "input#email"]).attributes
        #expect(attrs.count == 2)
        #expect(attrs.first?.id == "user")
        #expect(attrs.last?.id == "email")
    }

    /// `FormsMapSelector.attributes` returns empty for an unsupported selector (shadow DOM).
    @Test
    func formsMapSelector_unsupportedSelector_returnsEmpty() {
        let attrs = FormsMapSelector.single("div >>> input#user").attributes
        #expect(attrs.isEmpty)
    }
}

// MARK: - Helpers

private extension FillAssistRepositoryTests {
    func makeManifest(cid: String) -> FillAssistManifestResponseModel {
        let entry = FillAssistManifestEntryModel(
            cid: cid,
            deprecated: false,
            filename: "forms.v1.json",
            schema: "forms.v1.schema.json",
        )
        return FillAssistManifestResponseModel(
            buildId: "v1",
            gitSha: "abc",
            maps: ["forms": ["v1": entry]],
            timestamp: Date(timeIntervalSinceReferenceDate: 0),
        )
    }

    private func makeFormsMap(
        schemaVersion: String = "1.0.0",
        usernameSelector: String = "input#user",
        hosts: [String: String]? = nil,
    ) throws -> FormsMapResponseModel {
        let hostsJSON: String
        if let hosts {
            let entries = hosts.map { hostname, selector in
                """
                "\(hostname)": {"forms": [{"category": "account-login", "fields": {"username": ["\(selector)"]}}]}
                """
            }.joined(separator: ",")
            hostsJSON = "{\(entries)}"
        } else {
            hostsJSON = """
            {"example.com": {"forms": [{"category": "account-login", "fields": {"username": ["\(usernameSelector)"]}}]}}
            """
        }
        let json = """
        {"schemaVersion": "\(schemaVersion)", "hosts": \(hostsJSON)}
        """
        return try JSONDecoder.pascalOrSnakeCaseDecoder.decode(
            FormsMapResponseModel.self,
            from: Data(json.utf8),
        )
    }

    private func makeFormsMapWithPathnames() throws -> FormsMapResponseModel {
        let json = """
        {
            "schemaVersion": "1.0.0",
            "hosts": {
                "example.com": {
                    "forms": [{"category": "account-login", "fields": {"username": ["input#user1"]}}],
                    "pathnames": {
                        "/login": {"forms": [{"category": "account-login", "fields": {"username": ["input#user2"]}}]}
                    }
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
