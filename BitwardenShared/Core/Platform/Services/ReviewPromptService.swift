import AuthenticationServices
import BitwardenKit
import Foundation

// MARK: - ReviewPromptService

/// A protocol for a `ReviewPromptService` which determines if a user is eligible for a review prompt.
///
protocol ReviewPromptService {
    /// Clears all tracked user actions.
    ///
    func clearUserActions() async

    /// Determines if the user is eligible for a review prompt.
    ///
    /// - Returns: `true` if the user is eligible for a review prompt, `false` otherwise.
    ///
    func isEligibleForReviewPrompt() async -> Bool

    /// Sets app version that the review prompt was last shown for.
    ///
    func setReviewPromptShownVersion() async

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

    /// The service used to manage the credentials available for AutoFill suggestions.
    private let identityStore: CredentialIdentityStore

    /// The service used by the application to manage account state.
    private let stateService: StateService

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
        stateService: StateService,
    ) {
        self.appVersion = appVersion
        self.stateService = stateService
        self.identityStore = identityStore
    }

    func clearUserActions() async {
        if var reviewPromptData = await stateService.getReviewPromptData() {
            reviewPromptData.userActions = []
            await stateService.setReviewPromptData(reviewPromptData)
        }
    }

    func isEligibleForReviewPrompt() async -> Bool {
        let isAutofillEnabled = await identityStore.isAutofillEnabled()
        guard isAutofillEnabled, let reviewPromptData = await stateService.getReviewPromptData(),
              reviewPromptData.reviewPromptShownForVersion != appVersion else {
            return false
        }
        return reviewPromptData.userActions.contains { $0.count >= Constants.minimumUserActions }
    }

    func setReviewPromptShownVersion() async {
        var reviewPromptData = await stateService.getReviewPromptData() ?? ReviewPromptData()
        reviewPromptData.reviewPromptShownForVersion = appVersion
        await stateService.setReviewPromptData(reviewPromptData)
    }

    func trackUserAction(_ action: UserAction) async {
        var reviewPromptData = await stateService.getReviewPromptData() ?? ReviewPromptData()
        guard reviewPromptData.reviewPromptShownForVersion != appVersion else {
            return
        }
        reviewPromptData.addUserAction(action)
        await stateService.setReviewPromptData(reviewPromptData)
    }
}
