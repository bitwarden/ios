// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import UserNotifications
import XCTest

@testable import BitwardenShared

class OtherSettingsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<OtherSettingsState, OtherSettingsAction, OtherSettingsEffect>!
    var subject: OtherSettingsView!

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: OtherSettingsState())

        subject = OtherSettingsView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the sync now button performs the `.syncNow` effect.
    @MainActor
    func test_syncNow_tapped() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.syncNow)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .syncNow)
    }

    /// The connect to watch toggle is hidden if the device is not an iPhone.
    @MainActor
    func test_connectToWatchToggle_hidden() async throws {
        processor.state.shouldShowConnectToWatchToggle = false
        XCTAssertThrowsError(try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.connectToWatch))
    }

    /// The connect to watch toggle is visible if the device is an iPhone.
    @MainActor
    func test_connectToWatchToggle_visible() async throws {
        processor.state.shouldShowConnectToWatchToggle = true
        XCTAssertNoThrow(try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.connectToWatch))
    }

    /// The notification status shows on when notifications are allowed, without a button.
    @MainActor
    func test_notifications_on() throws {
        processor.state.notificationAuthorization = .authorized
        XCTAssertEqual(try subject.inspect().find(text: Localizations.on).string(), Localizations.on)
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.openSettings))
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.turnOnNow))
    }

    /// Tapping the turn on button performs the `.turnOnNotifications` effect when permission hasn't
    /// been decided.
    @MainActor
    func test_notifications_notDetermined_tap() async throws {
        processor.state.notificationAuthorization = .notDetermined
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.off))
        let button = try subject.inspect().find(asyncButton: Localizations.turnOnNow)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .turnOnNotifications)
    }

    /// Tapping the open settings button performs the `.turnOnNotifications` effect when
    /// notifications are denied.
    @MainActor
    func test_notifications_denied_tap() async throws {
        processor.state.notificationAuthorization = .denied
        let button = try subject.inspect().find(asyncButton: Localizations.openSettings)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .turnOnNotifications)
    }

    /// The Agent Access warning shows when Agent Access is on and notifications are off.
    @MainActor
    func test_notifications_agentAccessWarning_visible() throws {
        processor.state.notificationAuthorization = .denied
        processor.state.isAgentAccessEnabled = true
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessNotificationsOffWarning))
    }

    /// The Agent Access warning is hidden when Agent Access isn't on.
    @MainActor
    func test_notifications_agentAccessWarning_hidden() throws {
        processor.state.notificationAuthorization = .denied
        processor.state.isAgentAccessEnabled = false
        XCTAssertThrowsError(try subject.inspect().find(text: Localizations.agentAccessNotificationsOffWarning))
    }
}
