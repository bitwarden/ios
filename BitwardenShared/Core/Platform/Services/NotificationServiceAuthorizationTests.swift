import TestHelpers
import UserNotifications
import XCTest

@testable import BitwardenShared

class NotificationServiceAuthorizationTests: BitwardenTestCase {
    // MARK: Properties

    var subject: MockNotificationService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = MockNotificationService()
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `requestAlertAuthorizationIfNeeded()` requests alert, sound and badge authorization if the
    /// user hasn't been asked yet.
    func test_requestAlertAuthorizationIfNeeded_notDetermined() async throws {
        subject.authorizationStatus = .notDetermined

        _ = try await subject.requestAlertAuthorizationIfNeeded()

        XCTAssertEqual(subject.requestedOptions, [.alert, .sound, .badge])
    }

    /// `requestAlertAuthorizationIfNeeded()` doesn't ask again once the user has decided.
    func test_requestAlertAuthorizationIfNeeded_decided() async throws {
        for status in [UNAuthorizationStatus.denied, .authorized, .provisional] {
            subject.authorizationStatus = status

            let result = try await subject.requestAlertAuthorizationIfNeeded()

            XCTAssertEqual(result, status)
            XCTAssertNil(subject.requestedOptions)
        }
    }

    /// `requestAlertAuthorizationIfNeeded()` throws if the request fails.
    func test_requestAlertAuthorizationIfNeeded_error() async {
        subject.authorizationStatus = .notDetermined
        subject.requestAuthorizationResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.requestAlertAuthorizationIfNeeded()
        }
    }

    /// `UNAuthorizationStatus.allowsAlerts` is true only when the app can show notifications.
    func test_allowsAlerts() {
        XCTAssertTrue(UNAuthorizationStatus.authorized.allowsAlerts)
        XCTAssertTrue(UNAuthorizationStatus.provisional.allowsAlerts)
        XCTAssertTrue(UNAuthorizationStatus.ephemeral.allowsAlerts)
        XCTAssertFalse(UNAuthorizationStatus.denied.allowsAlerts)
        XCTAssertFalse(UNAuthorizationStatus.notDetermined.allowsAlerts)
    }
}
