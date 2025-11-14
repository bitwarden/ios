import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenShared

// swiftlint:disable:next type_body_length
class AutoFillProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var configService: MockConfigService!
    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var errorReporter: MockErrorReporter!
    var settingsRepository: MockSettingsRepository!
    var stateService: MockStateService!
    var subject: AutoFillProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        coordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
        errorReporter = MockErrorReporter()
        settingsRepository = MockSettingsRepository()
        stateService = MockStateService()

        subject = AutoFillProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                configService: configService,
                errorReporter: errorReporter,
                settingsRepository: settingsRepository,
                stateService: stateService,
            ),
            state: AutoFillState(),
        )
    }

    override func tearDown() {
        super.tearDown()

        configService = nil
        coordinator = nil
        errorReporter = nil
        settingsRepository = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.dismissSetUpAutofillActionCard` sets the user's vault autofill setup
    /// progress to complete.
    @MainActor
    func test_perform_dismissSetUpAutofillActionCard() async {
        stateService.activeAccount = .fixture()
        stateService.accountSetupAutofill["1"] = .setUpLater

        await subject.perform(.dismissSetUpAutofillActionCard)

        XCTAssertEqual(stateService.accountSetupAutofill["1"], .complete)
    }

    /// `perform(_:)` with `.dismissSetUpAutofillActionCard` logs an error and shows an alert if an
    /// error occurs.
    @MainActor
    func test_perform_dismissSetUpAutofillActionCard_error() async {
        await subject.perform(.dismissSetUpAutofillActionCard)

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `perform(_:)` with `.fetchSettingValues` fetches the setting values to display and updates the state.
    @MainActor
    func test_perform_fetchSettingValues() async {
        settingsRepository.getDefaultUriMatchTypeResult = .exact
        settingsRepository.getDisableAutoTotpCopyResult = .success(false)
        await subject.perform(.fetchSettingValues)
        XCTAssertEqual(subject.state.defaultUriMatchType, .exact)
        XCTAssertTrue(subject.state.isCopyTOTPToggleOn)

        settingsRepository.getDefaultUriMatchTypeResult = .regularExpression
        settingsRepository.getDisableAutoTotpCopyResult = .success(true)
        await subject.perform(.fetchSettingValues)
        XCTAssertEqual(subject.state.defaultUriMatchType, .regularExpression)
        XCTAssertFalse(subject.state.isCopyTOTPToggleOn)
    }

    /// `perform(_:)` with `.fetchSettingValues` logs an error and shows an alert if fetching the values fails.
    @MainActor
    func test_perform_fetchSettingValues_error() async {
        settingsRepository.getDisableAutoTotpCopyResult = .failure(StateServiceError.noActiveAccount)

        await subject.perform(.fetchSettingValues)

        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, StateServiceError.noActiveAccount)
    }

    /// `perform(_:)` with `.streamSettingsBadge` updates the state's badge state whenever it changes.
    @MainActor
    func test_perform_streamSettingsBadge() {
        stateService.activeAccount = .fixture()

        let task = Task {
            await subject.perform(.streamSettingsBadge)
        }
        defer { task.cancel() }

        let badgeState = SettingsBadgeState.fixture(vaultUnlockSetupProgress: .setUpLater)
        stateService.settingsBadgeSubject.send(badgeState)
        waitFor { subject.state.badgeState == badgeState }

        XCTAssertEqual(subject.state.badgeState, badgeState)
    }

    /// `perform(_:)` with `.streamSettingsBadge` logs an error if streaming the settings badge state fails.
    @MainActor
    func test_perform_streamSettingsBadge_error() async {
        await subject.perform(.streamSettingsBadge)

        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `receive(_:)` with `.appExtensionTapped` navigates to the app extension view.
    @MainActor
    func test_receive_appExtensionTapped() {
        subject.receive(.appExtensionTapped)
        XCTAssertEqual(coordinator.routes.last, .appExtension)
    }

    /// `.receive(_:)` with `.defaultUriMatchTypeChanged` updates the state's default URI match type value.
    @MainActor
    func test_receive_defaultUriMatchTypeChanged() {
        subject.receive(.defaultUriMatchTypeChanged(.host))
        waitFor(settingsRepository.updateDefaultUriMatchTypeValue == .host)
        XCTAssertEqual(subject.state.defaultUriMatchType, .host)
        XCTAssertEqual(settingsRepository.updateDefaultUriMatchTypeValue, .host)
    }

    /// `.receive(_:)` with `.passwordAutoFillTapped` navigates to the password autofill view.
    @MainActor
    func test_receive_passwordAutoFillTapped() {
        subject.receive(.passwordAutoFillTapped)
        XCTAssertEqual(coordinator.routes.last, .passwordAutoFill)
    }

    /// `receive(_:)` with `showSetUpAutofill(:)` has the coordinator navigate to the password
    /// autofill screen.
    @MainActor
    func test_receive_showSetUpAutofill() throws {
        subject.receive(.showSetUpAutofill)

        XCTAssertEqual(coordinator.routes, [.passwordAutoFill])
    }

    /// `.receive(_:)` with  `.toggleCopyTOTPToggle` updates the state.
    @MainActor
    func test_receive_toggleCopyTOTPToggle() throws {
        subject.state.isCopyTOTPToggleOn = false
        subject.receive(.toggleCopyTOTPToggle(true))

        XCTAssertTrue(subject.state.isCopyTOTPToggleOn)
        waitFor(settingsRepository.updateDisableAutoTotpCopyValue == false)
        try XCTAssertFalse(XCTUnwrap(settingsRepository.updateDisableAutoTotpCopyValue))
    }

    /// Updating the default URI match type value logs an error and shows an alert if it fails.
    @MainActor
    func test_updateDefaultUriMatchType_error() {
        settingsRepository.updateDefaultUriMatchTypeResult = .failure(StateServiceError.noActiveAccount)

        subject.receive(.defaultUriMatchTypeChanged(.exact))

        waitFor(!errorReporter.errors.isEmpty)
        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, StateServiceError.noActiveAccount)
    }

    /// Updating the disable auto-copy TOTP value logs an error and shows an alert if it fails.
    @MainActor
    func test_updateDisableAutoTotpCopy_error() {
        settingsRepository.updateDisableAutoTotpCopyResult = .failure(StateServiceError.noActiveAccount)

        subject.receive(.toggleCopyTOTPToggle(true))

        waitFor(!errorReporter.errors.isEmpty)
        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, StateServiceError.noActiveAccount)
    }

    /// Receiving `.defaultUriMatchTypeChanged(.regularExpression)` shows an alert to confirm the change
    /// Confirming it updates the `defaultUriMatchType`
    @MainActor
    func test_receive_regularExpressionUriMatchTypeSelected_confirm() async throws {
        subject.receive(.defaultUriMatchTypeChanged(.regularExpression))
        try await waitForAsync {
            !self.coordinator.alertShown.isEmpty
        }
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(coordinator.alertShown.last, Alert(
            title: Localizations.areYouSureYouWantToUseX(Localizations.regEx),
            message: Localizations.regularExpressionIsAnAdvancedOptionWithIncreasedRiskOfExposingCredentials,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in },
            ],
        ))
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(subject.state.defaultUriMatchType, .regularExpression)
        XCTAssertEqual(settingsRepository.updateDefaultUriMatchTypeValue, .regularExpression)
    }

    /// Receiving `.defaultUriMatchTypeChanged(.regularExpression)` shows an alert to confirm the change
    /// Canceling it keeps the `defaultUriMatchType` value
    @MainActor
    func test_receive_advancedUriMatchTypeSelected_cancel() async throws {
        XCTAssertEqual(subject.state.defaultUriMatchType, .domain)
        subject.receive(.defaultUriMatchTypeChanged(.regularExpression))
        try await waitForAsync {
            !self.coordinator.alertShown.isEmpty
        }
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(coordinator.alertShown.last, Alert(
            title: Localizations.areYouSureYouWantToUseX(Localizations.regEx),
            message: Localizations.regularExpressionIsAnAdvancedOptionWithIncreasedRiskOfExposingCredentials,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in },
            ],
        ))
        try await alert.tapAction(title: Localizations.cancel)

        XCTAssertEqual(subject.state.defaultUriMatchType, .domain)
    }

    /// `receive(_:)` with `.regularExpression` shows an alert for navigating to the web vault
    /// When `Learn more` is tapped on the alert navigates the user to the web app
    @MainActor
    func test_receive_regularExpressionUriMatchTypeSelected_learnMore() async throws {
        subject.receive(.defaultUriMatchTypeChanged(.regularExpression))
        try await waitForAsync {
            !self.coordinator.alertShown.isEmpty
        }
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.yes)

        waitFor(settingsRepository.updateDefaultUriMatchTypeValue == .regularExpression)
        let alertLearnMore = try XCTUnwrap(coordinator.alertShown.last)

        XCTAssertEqual(alertLearnMore, Alert(
            title: Localizations.keepYourCredentialsSecure,
            message: Localizations.learnMoreAboutHowToKeepCredentialsSecureWhenUsingX(Localizations.regEx),
            alertActions: [
                AlertAction(title: Localizations.close, style: .cancel),
                AlertAction(title: Localizations.learnMore, style: .default) { _ in },
            ],
        ))

        try await alertLearnMore.tapAction(title: Localizations.learnMore)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.uriMatchDetections)
    }

    /// Receiving `.defaultUriMatchTypeChanged(.startsWith)` shows an alert to confirm the change
    /// Confirming it updates the `defaultUriMatchType`
    @MainActor
    func test_receive_startsWithUriMatchTypeSelected_confirm() async throws {
        subject.receive(.defaultUriMatchTypeChanged(.startsWith))
        try await waitForAsync {
            !self.coordinator.alertShown.isEmpty
        }
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(coordinator.alertShown.last, Alert(
            title: Localizations.areYouSureYouWantToUseX(Localizations.startsWith),
            message: Localizations.startsWithIsAnAdvancedOptionWithIncreasedRiskOfExposingCredentials,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in },
            ],
        ))
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(subject.state.defaultUriMatchType, .startsWith)
        XCTAssertEqual(settingsRepository.updateDefaultUriMatchTypeValue, .startsWith)
    }

    /// Receiving `.defaultUriMatchTypeChanged(.startsWith)` shows an alert to confirm the change
    /// Canceling it keeps the `defaultUriMatchType` value
    @MainActor
    func test_receive_startsWithUriMatchTypeSelected_cancel() async throws {
        XCTAssertEqual(subject.state.defaultUriMatchType, .domain)
        subject.receive(.defaultUriMatchTypeChanged(.startsWith))
        try await waitForAsync {
            !self.coordinator.alertShown.isEmpty
        }
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(coordinator.alertShown.last, Alert(
            title: Localizations.areYouSureYouWantToUseX(Localizations.startsWith),
            message: Localizations.startsWithIsAnAdvancedOptionWithIncreasedRiskOfExposingCredentials,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in },
            ],
        ))
        try await alert.tapAction(title: Localizations.cancel)

        XCTAssertEqual(subject.state.defaultUriMatchType, .domain)
    }

    /// `receive(_:)` with `.startsWith` shows an alert for navigating to the web vault
    /// When `Learn more` is tapped on the alert navigates the user to the web app
    @MainActor
    func test_receive_startsWithUriMatchTypeSelected_learnMore() async throws {
        subject.receive(.defaultUriMatchTypeChanged(.startsWith))
        try await waitForAsync {
            !self.coordinator.alertShown.isEmpty
        }
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.yes)

        waitFor(settingsRepository.updateDefaultUriMatchTypeValue == .startsWith)
        let alertLearnMore = try XCTUnwrap(coordinator.alertShown.last)

        XCTAssertEqual(alertLearnMore, Alert(
            title: Localizations.keepYourCredentialsSecure,
            message: Localizations.learnMoreAboutHowToKeepCredentialsSecureWhenUsingX(Localizations.startsWith),
            alertActions: [
                AlertAction(title: Localizations.close, style: .cancel),
                AlertAction(title: Localizations.learnMore, style: .default) { _ in },
            ],
        ))

        try await alertLearnMore.tapAction(title: Localizations.learnMore)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.uriMatchDetections)
    }

    /// `receive(_:)` with `.clearURL` clears the URL in the state.
    @MainActor
    func test_receive_clearURL() {
        subject.state.url = .example
        subject.receive(.clearUrl)
        XCTAssertNil(subject.state.url)
    }
}
