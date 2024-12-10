import AuthenticationServices
import Foundation

/// A protocol for a `ReviewPromptService` which determines if a user is eligible for a review prompt.
///
protocol ReviewPromptService {
    /// Determines if the user is eligible for a review prompt.
    ///
    /// - Returns: `true` if the user is eligible for a review prompt, `false` otherwise.
    func isEligibleForReviewPrompt() async -> Bool
}

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
        if reviewPromptData.userActions.isEmpty {
            return false
        }
        for userActionItem in reviewPromptData.userActions where userActionItem.count >= 3 {
            return true
        }
        return false
    }
}
