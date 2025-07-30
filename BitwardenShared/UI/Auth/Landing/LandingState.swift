import BitwardenKit

// MARK: - LandingState

/// An object that defines the current state of a `LandingView`.
///
struct LandingState: Equatable {
    // MARK: Properties

    /// The email address provided by the user.
    var email: String

    /// A flag indicating if the continue button is enabled.
    var isContinueButtonEnabled: Bool {
        !email.isEmpty
    }

    /// A flag indicating if the "Remember Me" toggle is on.
    var isRememberMeOn: Bool

    /// The user's current account profile state and alternative accounts.
    var profileSwitcherState: ProfileSwitcherState

    /// The region selected by the user.
    var region: RegionType

    /// A toast message to show in the view.
    var toast: Toast?

    // MARK: Initialization

    /// Creates a new `LandingState`.
    ///
    /// - Parameters:
    ///   - email: The email address provided by the user.
    ///   - isRememberMeOn: A flag indicating if the "Remember Me" toggle is on.
    ///   - profileSwitcherState: State for the profile switcher.
    ///   - region: The region selected by the user.
    ///
    init(
        email: String = "",
        isRememberMeOn: Bool = false,
        profileSwitcherState: ProfileSwitcherState = .empty(
            shouldAlwaysHideAddAccount: true,
            showPlaceholderToolbarIcon: true
        ),
        region: RegionType = .unitedStates
    ) {
        self.email = email
        self.isRememberMeOn = isRememberMeOn
        self.profileSwitcherState = profileSwitcherState
        self.region = region
    }
}
