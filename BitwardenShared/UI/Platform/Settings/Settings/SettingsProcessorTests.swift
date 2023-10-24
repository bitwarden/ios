import XCTest

@testable import BitwardenShared

class SettingsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var settingsRepository: MockSettingsRepository!
    var subject: SettingsProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        settingsRepository = MockSettingsRepository()

        subject = SettingsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                settingsRepository: settingsRepository
            ),
            state: SettingsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.logout` presents a logout confirmation alert.
    func test_receive_logout() async throws {
        subject.receive(.logout)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.logOut)
        XCTAssertEqual(alert.message, Localizations.logoutConfirmation)
        XCTAssertEqual(alert.preferredStyle, .alert)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        // Tapping yes logs the user out.
        await alert.alertActions[0].handler?(alert.alertActions[0])

        XCTAssertTrue(settingsRepository.logoutCalled)
        XCTAssertEqual(coordinator.routes.last, .logout)
    }
}
