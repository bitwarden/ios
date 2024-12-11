import AuthenticationServices
import Foundation

// MARK: - ReviewPromptService

/// A protocol for a `ReviewPromptService` which determines if a user is eligible for a review prompt.
///
protocol ReviewPromptService {
    /// Determines if the user is eligible for a review prompt.
    ///
    /// - Returns: `true` if the user is eligible for a review prompt, `false` otherwise.
    func isEligibleForReviewPrompt() async -> Bool

    /// Tracks a user action.
    ///
    /// - Parameter action: The user action to track.
    ///
    func trackUserAction(_ action: UserAction) async
}

// MARK: - DefaultReviewPromptService

/// A default implementation of a `ReviewPromptService`.
///
class DefaultReviewPromptService: ReviewPromptService {
    /// The current app version.
    private let appVersion: String

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The service used to manage the credentials available for AutoFill suggestions.
    private let identityStore: CredentialIdentityStore

    // MARK: Initialization

    /// Initialize a `ReviewPromptService`.
    ///
    /// - Parameters:
    ///   - appVersion: The current app version.
    ///   - identityStore: The service used to manage the credentials available for AutoFill suggestions.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        appVersion: String,
        identityStore: CredentialIdentityStore = ASCredentialIdentityStore.shared,
        stateService: StateService
    ) {
        self.appVersion = appVersion
        self.stateService = stateService
        self.identityStore = identityStore
    }

    func isEligibleForReviewPrompt() async -> Bool {
        // Check if autofill is enabled
        let isAutofillEnabled = await identityStore.isAutofillEnabled()
        guard isAutofillEnabled else {
            return false
        }

        // Check if the review prompt has already been shown for the current app version
        guard let reviewPromptData = await stateService.getReviewPromptData(),
              reviewPromptData.reviewPromptShownForVersion != appVersion else {
            return false
        }

        // Check if any user action has been performed at least three times
        return reviewPromptData.userActions.contains { $0.count >= Constants.minimumUserActions }
    }

    func trackUserAction(_ action: UserAction) async {
        var reviewPromptData = await stateService.getReviewPromptData() ?? ReviewPromptData()
        if reviewPromptData.reviewPromptShownForVersion != appVersion {
            reviewPromptData.addUserAction(action)
        }
        await stateService.setReviewPromptData(reviewPromptData)
    }
}
