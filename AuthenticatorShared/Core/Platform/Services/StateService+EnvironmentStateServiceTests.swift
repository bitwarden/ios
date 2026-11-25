// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import Testing

@testable import AuthenticatorShared

// MARK: - StateServiceEnvironmentStateServiceTests

struct StateServiceEnvironmentStateServiceTests {
    // MARK: Properties

    let appSettingsStore: MockAppSettingsStore
    let subject: DefaultStateService

    // MARK: Initialization

    init() {
        appSettingsStore = MockAppSettingsStore()
        subject = DefaultStateService(
            appSettingsStore: appSettingsStore,
            dataStore: DataStore(errorReporter: MockErrorReporter(), storeType: .memory),
        )
    }

    // MARK: Tests

    /// `getEnvironmentURLs(userId:)` returns `nil` for any user.
    @Test(arguments: [nil, "localtest"] as [String?])
    func getEnvironmentURLs(userId: String?) async throws {
        let result = try await subject.getEnvironmentURLs(userId: userId)

        #expect(result == nil)
    }

    /// `getPreAuthEnvironmentURLs()` returns the URLs stored in `AppSettingsStore`.
    @Test
    func getPreAuthEnvironmentURLs() async {
        appSettingsStore.preAuthEnvironmentURLs = .defaultEU

        let result = await subject.getPreAuthEnvironmentURLs()

        #expect(result == .defaultEU)
    }

    /// `getPreAuthEnvironmentURLs()` returns `nil` when no URLs are stored.
    @Test
    func getPreAuthEnvironmentURLs_notSet() async {
        let result = await subject.getPreAuthEnvironmentURLs()

        #expect(result == nil)
    }

    /// `setPreAuthEnvironmentURLs(_:)` persists the URLs to `AppSettingsStore`.
    @Test
    func setPreAuthEnvironmentURLs() async {
        await subject.setPreAuthEnvironmentURLs(.defaultEU)

        #expect(appSettingsStore.preAuthEnvironmentURLs == .defaultEU)
    }
}
