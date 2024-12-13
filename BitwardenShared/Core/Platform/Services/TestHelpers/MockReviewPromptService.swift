
import Combine
import Foundation

@testable import BitwardenShared

class MockReviewPromptService: ReviewPromptService {
    var isEligibleForReviewPromptResult: Bool = false
    var userActions: [BitwardenShared.UserAction] = []

    func isEligibleForReviewPrompt() async -> Bool {
        isEligibleForReviewPromptResult
    }

    func trackUserAction(_ action: BitwardenShared.UserAction) async {
        userActions.append(action)
    }
}
