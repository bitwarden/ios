import BitwardenKitMocks
import BitwardenResources
import Testing
import UserNotifications

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - NotificationExtensionHelperTests

@MainActor
struct NotificationExtensionHelperTests {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore
    var errorReporter: MockErrorReporter
    var subject: DefaultNotificationExtensionHelper

    // MARK: Initialization

    init() {
        appSettingsStore = MockAppSettingsStore()
        errorReporter = MockErrorReporter()
        subject = DefaultNotificationExtensionHelper(
            appSettingsStore: appSettingsStore,
            errorReporter: errorReporter,
        )
    }

    // MARK: Tests

    /// `processNotification(content:)` updates the title and body with the user's email when the
    /// payload is valid and the user is found in the accounts store.
    @Test
    func processNotification_authRequest_updatesContent() async throws {
        let userId = "user-1"
        let email = "user@bitwarden.com"
        let account = Account.fixture(profile: .fixture(email: email, userId: userId))
        appSettingsStore.state = State(accounts: [userId: account], activeUserId: userId)

        let payloadString = try jsonString(LoginRequestNotification(id: "request-1", userId: userId))
        let content = makeContent(type: 15, payload: payloadString)

        let result = await subject.processNotification(content: content)

        #expect(result.title == Localizations.logInRequested)
        #expect(result.body == Localizations.confirmLogInAttemptForX(email))
        #expect(errorReporter.errors.isEmpty)
    }

    /// `processNotification(content:)` returns the original content unchanged when the user ID
    /// in the payload does not match any known account.
    @Test
    func processNotification_authRequest_returnsOriginalContent_whenUserNotFound() async throws {
        appSettingsStore.state = State(accounts: [:], activeUserId: nil)

        let payloadString = try jsonString(LoginRequestNotification(id: "request-1", userId: "unknown-user"))
        let content = makeContent(type: 15, payload: payloadString)
        let originalBody = content.body

        let result = await subject.processNotification(content: content)

        #expect(result.body == originalBody)
        #expect(errorReporter.errors.isEmpty)
    }

    /// `processNotification(content:)` returns the original content unchanged and logs an error
    /// when the notification payload cannot be decoded.
    @Test
    func processNotification_logsError_whenPayloadMalformed() async throws {
        let content = makeContent(type: 15, payload: "not valid json {{{")
        let originalBody = content.body

        let result = await subject.processNotification(content: content)

        #expect(result.body == originalBody)
        #expect(errorReporter.errors.count == 1)
        let error = try #require(errorReporter.errors.first as? PushNotificationDataError)
        guard case let .payloadDecodingFailed(type, _) = error else {
            Issue.record("Expected payloadDecodingFailed, got \(error)")
            return
        }
        #expect(type == .authRequest)
    }

    /// `processNotification(content:)` returns the original content unchanged when the notification
    /// has no `"data"` key in `userInfo` (e.g. a non-Bitwarden notification).
    @Test
    func processNotification_returnsOriginalContent_whenNoDataKey() async throws {
        let content = UNMutableNotificationContent()
        content.body = "Some other notification"

        let result = await subject.processNotification(content: content)

        #expect(result.body == "Some other notification")
        #expect(errorReporter.errors.count == 1)
        let error = try #require(errorReporter.errors.first as? PushNotificationDataError)
        guard case .missingDataDictionary = error else {
            Issue.record("Expected missingDataDictionary, got \(error)")
            return
        }
    }

    /// `processNotification(content:)` returns the original content unchanged when the notification
    /// type is not handled.
    @Test
    func processNotification_returnsOriginalContent_whenTypeNotHandled() async throws {
        let userId = "user-1"
        let account = Account.fixture(profile: .fixture(email: "user@bitwarden.com", userId: userId))
        appSettingsStore.state = State(accounts: [userId: account], activeUserId: userId)

        let payloadString = try jsonString(LoginRequestNotification(id: "request-1", userId: userId))
        // syncCipherUpdate = type 0, not handled by the extension
        let content = makeContent(type: 0, payload: payloadString)
        let originalBody = content.body

        let result = await subject.processNotification(content: content)

        #expect(result.body == originalBody)
        #expect(errorReporter.errors.isEmpty)
    }

    // MARK: Private

    /// Encodes a `Codable` value to a compact JSON string.
    private func jsonString<T: Encodable>(
        _ value: T,
        sourceLocation: SourceLocation = #_sourceLocation,
    ) throws -> String {
        let data = try JSONEncoder().encode(value)
        return try #require(String(bytes: data, encoding: .utf8), sourceLocation: sourceLocation)
    }

    /// Creates a `UNMutableNotificationContent` with the given notification type and payload.
    private func makeContent(type: Int, payload: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.body = "Confirm login attempt"
        content.userInfo = [
            "data": [
                "type": type,
                "payload": payload,
            ] as [String: Any],
        ]
        return content
    }
}
