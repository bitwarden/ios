// MARK: - AboutProcessor

import Foundation

/// The processor used to manage state and handle actions for the `AboutView`.
///
final class AboutProcessor: StateProcessor<AboutState, AboutAction, Void> {
    // MARK: Types

    typealias Services = HasEnvironmentService
        & HasErrorReporter
        & HasPasteboardService
        & HasSystemDevice

    // MARK: Properties

    /// Additional info to be used by this processor.
    private let aboutAdditionalInfo: AboutAdditionalInfo

    /// The app's bundle identifier.
    private let bundleIdentifier: String?

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a new `AboutProcessor`.
    ///
    /// - Parameters:
    ///   - aboutAdditionalInfo: Additional info to be used by this processor.
    ///   - bundleIdentifier: The app's bundle identifier.
    ///   - coordinator: The coordinator used to manage navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    init(
        aboutAdditionalInfo: AboutAdditionalInfo,
        bundleIdentifier: String? = Bundle.main.bundleIdentifier,
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        services: Services,
        state: AboutState
    ) {
        self.aboutAdditionalInfo = aboutAdditionalInfo
        self.bundleIdentifier = bundleIdentifier
        self.coordinator = coordinator
        self.services = services

        // Set the initial value of the crash logs toggle.
        var state = state
        state.isSubmitCrashLogsToggleOn = self.services.errorReporter.isEnabled

        super.init(state: state)
    }

    // MARK: Methods

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
        case .webVaultTapped:
            coordinator.showAlert(.webVaultAlert {
                self.state.url = self.services.environmentService.webVaultURL
            })
        }
    }

    // MARK: - Private Methods

    /// Prepare the text to be copied.
    private func handleVersionTapped() {
        var buildVariant = switch bundleIdentifier {
        case "com.8bit.bitwarden.beta": "Beta"
        case "com.8bit.bitwarden": "Production"
        default: "Unknown"
        }
        buildVariant = "📦 \(buildVariant)"
        let hardwareInfo = "📱 \(services.systemDevice.modelIdentifier)"
        let osInfo = "🍏 \(services.systemDevice.systemName) \(services.systemDevice.systemVersion)"
        let deviceInfo = "\(hardwareInfo) \(osInfo) \(buildVariant)"
        var infoParts = [
            state.copyrightText,
            "",
            state.version,
            deviceInfo,
        ]
        if !aboutAdditionalInfo.ciBuildInfo.isEmpty {
            infoParts.append(
                contentsOf: aboutAdditionalInfo.ciBuildInfo
                    .filter { !$0.value.isEmpty }
                    .map { key, value in
                        "\(key) \(value)"
                    }
            )
        }
        services.pasteboardService.copy(infoParts.joined(separator: "\n"))
        state.toast = Toast(title: Localizations.valueHasBeenCopied(Localizations.appInfo))
    }
}

/// Protocol for additional info used by the `AboutProcessor`
protocol AboutAdditionalInfo {
    /// CI Build information.
    var ciBuildInfo: KeyValuePairs<String, String> { get }
}

/// Default implementation of `AboutAdditionalInfo`
struct DefaultAboutAdditionalInfo: AboutAdditionalInfo {
    var ciBuildInfo: KeyValuePairs<String, String> {
        CIBuildInfo.info
    }
}
