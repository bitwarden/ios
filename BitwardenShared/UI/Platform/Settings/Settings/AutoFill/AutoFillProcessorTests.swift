import XCTest

@testable import BitwardenShared

class AutoFillProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var errorReporter: MockErrorReporter!
    var settingsRepository: MockSettingsRepository!
    var subject: AutoFillProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute>()
        errorReporter = MockErrorReporter()
        settingsRepository = MockSettingsRepository()

        subject = AutoFillProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                settingsRepository: settingsRepository
            ),
            state: AutoFillState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        settingsRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.fetchSettingValues` fetches the setting values to display and updates the state.
    func test_perform_fetchSettingValues() async {
        settingsRepository.getDisableAutoTotpCopyResult = .success(false)
        await subject.perform(.fetchSettingValues)
        XCTAssertTrue(subject.state.isCopyTOTPToggleOn)

        settingsRepository.getDisableAutoTotpCopyResult = .success(true)
        await subject.perform(.fetchSettingValues)
        XCTAssertFalse(subject.state.isCopyTOTPToggleOn)
    }

    /// `perform(_:)` with `.fetchSettingValues` logs an error and shows an alert if fetching the values fails.
    func test_perform_fetchSettingValues_error() async {
        settingsRepository.getDisableAutoTotpCopyResult = .failure(StateServiceError.noActiveAccount)

        await subject.perform(.fetchSettingValues)

        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, StateServiceError.noActiveAccount)
    }

    /// `receive(_:)` with `.appExtensionTapped` navigates to the app extension view.
    func test_receive_appExtensionTapped() {
        subject.receive(.appExtensionTapped)
        XCTAssertEqual(coordinator.routes.last, .appExtension)
    }

    /// `.receive(_:)` with `.passwordAutoFillTapped` navigates to the password autofill view.
    func test_receive_passwordAutoFillTapped() {
        subject.receive(.passwordAutoFillTapped)
        XCTAssertEqual(coordinator.routes.last, .passwordAutoFill)
    }

    /// `.receive(_:)` with  `.toggleCopyTOTPToggle` updates the state.
    func test_receive_toggleCopyTOTPToggle() throws {
        subject.state.isCopyTOTPToggleOn = false
        subject.receive(.toggleCopyTOTPToggle(true))

        XCTAssertTrue(subject.state.isCopyTOTPToggleOn)
        waitFor(settingsRepository.updateDisableAutoTotpCopyValue == false)
        try XCTAssertFalse(XCTUnwrap(settingsRepository.updateDisableAutoTotpCopyValue))
    }

    /// Updating the disable auto-copy TOTP value logs an error and shows an alert if it fails.
    func test_updateDisableAutoTotpCopy_error() {
        settingsRepository.updateDisableAutoTotpCopyResult = .failure(StateServiceError.noActiveAccount)

        subject.receive(.toggleCopyTOTPToggle(true))

        waitFor(!errorReporter.errors.isEmpty)
        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, StateServiceError.noActiveAccount)
    }
}
