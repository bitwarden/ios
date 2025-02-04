import Combine
import Foundation

@testable import BitwardenShared

class MockReviewPromptService: ReviewPromptService {
    var isEligibleForReviewPromptResult: Bool = false
    var userActions: [BitwardenShared.UserAction] = []
    var setReviewPromptShownVersionCalled = false

    func isEligibleForReviewPrompt() async -> Bool {
        isEligibleForReviewPromptResult
    }

    func trackUserAction(_ action: BitwardenShared.UserAction) async {
        userActions.append(action)
    }

    func clearUserActions() async {
        userActions.removeAll()
    }

    func setReviewPromptShownVersion() async {
        setReviewPromptShownVersionCalled = true
    }
}
