import BitwardenKitMocks
import Foundation
import Networking
import Testing

@testable import BitwardenKit

// MARK: - DeviceIdentifierRequestHandlerTests

struct DeviceIdentifierRequestHandlerTests {
    // MARK: Properties

    let appIDSettingsStore: MockAppIDSettingsStore
    let subject: DeviceIdentifierRequestHandler

    // MARK: Initialization

    init() {
        appIDSettingsStore = MockAppIDSettingsStore()
        subject = DeviceIdentifierRequestHandler(
            appIDService: AppIDService(appIDSettingsStore: appIDSettingsStore),
        )
    }

    // MARK: Tests

    /// `handle(_:)` adds the `Device-Identifier` header with the app's ID, creating and persisting
    /// the app ID if one doesn't exist.
    @Test
    func handle_addsDeviceIdentifierHeader() async throws {
        var request = HTTPRequest(url: URL(string: "https://example.com")!)

        let handledRequest = try await subject.handle(&request)

        let appID = try #require(appIDSettingsStore.appID)
        #expect(handledRequest.headers["Device-Identifier"] == appID)
        #expect(request.headers["Device-Identifier"] == appID)
    }

    /// `handle(_:)` uses the same app ID across multiple requests.
    @Test
    func handle_consistentAcrossRequests() async throws {
        var firstRequest = HTTPRequest(url: URL(string: "https://example.com")!)
        var secondRequest = HTTPRequest(url: URL(string: "https://example.com")!)

        let firstHandledRequest = try await subject.handle(&firstRequest)
        let secondHandledRequest = try await subject.handle(&secondRequest)

        #expect(firstHandledRequest.headers["Device-Identifier"] != nil)
        #expect(firstHandledRequest.headers["Device-Identifier"] == secondHandledRequest.headers["Device-Identifier"])
    }

    /// `handle(_:)` overwrites an existing `Device-Identifier` header value with the app's ID.
    @Test
    func handle_overwritesExistingHeader() async throws {
        appIDSettingsStore.appID = "APP_ID"
        var request = HTTPRequest(
            url: URL(string: "https://example.com")!,
            headers: ["Device-Identifier": "OTHER_ID"],
        )

        let handledRequest = try await subject.handle(&request)

        #expect(handledRequest.headers["Device-Identifier"] == "APP_ID")
    }

    /// `handle(_:)` uses the persisted app ID when one exists.
    @Test
    func handle_usesPersistedAppID() async throws {
        appIDSettingsStore.appID = "APP_ID"
        var request = HTTPRequest(url: URL(string: "https://example.com")!)

        let handledRequest = try await subject.handle(&request)

        #expect(handledRequest.headers["Device-Identifier"] == "APP_ID")
        #expect(appIDSettingsStore.appID == "APP_ID")
    }
}
