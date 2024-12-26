import Foundation

// MARK: - TwoFactorDisplayState

/// An enum to track a user's status vis-à-vis the TwoFactorNotice notice screen
enum TwoFactorNoticeDisplayState: Codable, Equatable {
    /// The user has seen the screen and indicated they can access their email.
    case canAccessEmail

    /// The user has indicated they can access their email
    /// as specified by the Permanent mode of the notice
    case canAccessEmailPermanent

    /// The user has not seen the screen.
    case hasNotSeen

    /// The user has seen the screen, at the indicated Date, and selected "remind me later".
    case seen(Date)
}

// MARK: - TwoFactorNoticeHelper

/// A protocol for a helper object to handle deciding whether or not to display
/// the two-factor notice, and displaying it if so.
///
protocol TwoFactorNoticeHelper {
    /// Determines whether or not the user should see the two-factor notice.
    /// If so, then this displays that notice.
    func maybeShowTwoFactorNotice() async
}

// MARK: - DefaultTwoFactorNoticeHelper

/// A default implementation of `TwoFactorNoticeHelper`
///
@MainActor
class DefaultTwoFactorNoticeHelper: TwoFactorNoticeHelper {
    // MARK: Types

    typealias Services = HasConfigService
        & HasEnvironmentService
        & HasErrorReporter
        & HasPolicyService
        & HasStateService
        & HasTimeProvider

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultRoute, AuthAction>

    /// The services used by this helper.
    private var services: Services

    // MARK: Initialization

    /// Initialize a `TwoFactorNoticeHelper`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this helper.
    ///
    init(
        coordinator: AnyCoordinator<VaultRoute, AuthAction>,
        services: Services
    ) {
        self.coordinator = coordinator
        self.services = services
    }

    // MARK: Methods

    /// Checks if we need to display the notice for not having two-factor set up
    /// and displays the notice if necessary
    ///
    func maybeShowTwoFactorNotice() async {
        let temporary = await services.configService.getFeatureFlag(
            .newDeviceVerificationTemporaryDismiss,
            defaultValue: false
        )
        let permanent = await services.configService.getFeatureFlag(
            .newDeviceVerificationPermanentDismiss,
            defaultValue: false
        )
        guard temporary || permanent else { return }
        do {
            guard services.environmentService.region != .selfHosted,
                  try await !services.stateService.doesActiveAccountHaveTwoFactor(),
                  await !services.policyService.policyAppliesToUser(.requireSSO)
            else { return }

            let emailAddress = try await services.stateService.getActiveAccount().profile.email

            let state = try await services.stateService.getTwoFactorNoticeDisplayState()
            switch state {
            case .canAccessEmail:
                if permanent {
                    coordinator.navigate(to: .twoFactorNotice(allowDelay: !permanent, emailAddress: emailAddress))
                } else {
                    return
                }
            case .canAccessEmailPermanent:
                return
            case .hasNotSeen:
                coordinator.navigate(to: .twoFactorNotice(allowDelay: !permanent, emailAddress: emailAddress))
            case let .seen(date):
                if services.timeProvider.timeSince(date) >= Constants.twoFactorNoticeDelayInterval {
                    coordinator.navigate(to: .twoFactorNotice(allowDelay: !permanent, emailAddress: emailAddress))
                }
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}
