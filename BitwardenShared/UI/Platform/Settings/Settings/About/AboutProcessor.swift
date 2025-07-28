// MARK: - AboutProcessor

import BitwardenResources
import Foundation

/// The processor used to manage state and handle actions for the `AboutView`.
///
final class AboutProcessor: StateProcessor<AboutState, AboutAction, AboutEffect> {
    // MARK: Types

    typealias Services = HasAppInfoService
        & HasConfigService
        & HasEnvironmentService
        & HasErrorReporter
        & HasFlightRecorder
        & HasPasteboardService

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a new `AboutProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used to manage navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        services: Services,
        state: AboutState
    ) {
        self.coordinator = coordinator
        self.services = services

        // Set the initial value of the crash logs toggle.
        var state = state
        state.copyrightText = services.appInfoService.copyrightString
        state.isSubmitCrashLogsToggleOn = services.errorReporter.isEnabled
        state.version = services.appInfoService.versionString

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AboutEffect) async {
        switch effect {
        case .streamFlightRecorderLog:
            await streamFlightRecorderLog()
        case let .toggleFlightRecorder(isOn):
            if isOn {
                coordinator.navigate(to: .enableFlightRecorder)
            } else {
                await services.flightRecorder.disableFlightRecorder()
            }
        }
    }

    override func receive(_ action: AboutAction) {
        switch action {
        case .clearAppReviewURL:
            state.appReviewUrl = nil
        case .clearURL:
            state.url = nil
        case .helpCenterTapped:
            state.url = ExternalLinksConstants.helpAndFeedback
        case .learnAboutOrganizationsTapped:
            coordinator.showAlert(.learnAboutOrganizationsAlert {
                self.state.url = ExternalLinksConstants.aboutOrganizations
            })
        case .privacyPolicyTapped:
            coordinator.showAlert(.privacyPolicyAlert {
                self.state.url = ExternalLinksConstants.privacyPolicy
            })
        case .rateTheAppTapped:
            coordinator.showAlert(.appStoreAlert {
                self.state.appReviewUrl = ExternalLinksConstants.appReview
            })
        case let .toastShown(newValue):
            state.toast = newValue
        case let .toggleSubmitCrashLogs(isOn):
            state.isSubmitCrashLogsToggleOn = isOn
            services.errorReporter.isEnabled = isOn
        case .versionTapped:
            handleVersionTapped()
        case .viewFlightRecorderLogsTapped:
            coordinator.navigate(to: .flightRecorderLogs)
        case .webVaultTapped:
            coordinator.showAlert(.webVaultAlert {
                self.state.url = self.services.environmentService.webVaultURL
            })
        }
    }

    // MARK: - Private Methods

    /// Prepare the text to be copied.
    private func handleVersionTapped() {
        services.pasteboardService.copy(services.appInfoService.appInfoString)
        state.toast = Toast(title: Localizations.valueHasBeenCopied(Localizations.appInfo))
    }

    /// Streams the flight recorder's active log metadata.
    private func streamFlightRecorderLog() async {
        for await activeLog in await services.flightRecorder.activeLogPublisher().values {
            state.flightRecorderActiveLog = activeLog
        }
    }
}
