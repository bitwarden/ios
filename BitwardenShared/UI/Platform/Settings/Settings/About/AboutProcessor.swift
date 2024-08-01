// MARK: - AboutProcessor

/// The processor used to manage state and handle actions for the `AboutView`.
///
final class AboutProcessor: StateProcessor<AboutState, AboutAction, Void> {
    // MARK: Types

    typealias Services = HasEnvironmentService
        & HasErrorReporter
        & HasPasteboardService

    // MARK: Properties

    /// Additional info to be used by this processor.
    private let aboutAdditionalInfo: AboutAdditionalInfo

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services used by this processor.
    private let services: Services

    /// A `SystemDevice` instance used to get device details.
    private let systemDevice: SystemDevice

    // MARK: Initialization

    /// Initializes a new `AboutProcessor`.
    ///
    /// - Parameters:
    ///   - aboutAdditionalInfo: Additional info to be used by this processor.
    ///   - coordinator: The coordinator used to manage navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///   - systemDevice: A `SystemDevice` instance used to get device details.
    init(
        aboutAdditionalInfo: AboutAdditionalInfo,
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        services: Services,
        state: AboutState,
        systemDevice: SystemDevice
    ) {
        self.aboutAdditionalInfo = aboutAdditionalInfo
        self.coordinator = coordinator
        self.services = services
        self.systemDevice = systemDevice

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
        var infoParts = [
            state.copyrightText + "\n",
            state.version,
            "\n-------- Device --------\n",
            "Model: \(systemDevice.modelIdentifier)",
            "OS: \(systemDevice.systemName) \(systemDevice.systemVersion)",
        ]
        if !aboutAdditionalInfo.ciBuildInfo.isEmpty {
            infoParts.append("\n------- CI Info --------\n")
            infoParts.append(
                contentsOf: aboutAdditionalInfo.ciBuildInfo.map { key, value in
                    "\(key): \(value)"
                }
                .sorted()
            )
        }
        services.pasteboardService.copy(infoParts.joined(separator: "\n"))
        state.toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.appInfo))
    }
}

/// Protocol for additional info used by the `AboutProcessor`
protocol AboutAdditionalInfo {
    /// CI Build information.
    var ciBuildInfo: [String: String] { get }
}

/// Default implementation of `AboutAdditionalInfo`
struct DefaultAboutAdditionalInfo: AboutAdditionalInfo {
    var ciBuildInfo: [String: String] {
        CIBuildInfo.info
    }
}
