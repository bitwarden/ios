import StoreKit
import SwiftUI

/// A view modifier that requests a review when the view appears.
@available(iOS 16.0, *)
struct ReviewModifier: ViewModifier {
    /// The environment key for the request review function.
    @Environment(\.requestReview) var requestReview
    
    /// The eligibility for requesting a review.
    let isEligible: Bool

    /// The closure to execute after requesting a review.
    let afterClosure: () -> Void

    func body(content: Content) -> some View {
        content
            .task(id: isEligible) {
                if isEligible {
                    requestReview()
                    afterClosure()
                }
            }
    }
}

/// A view modifier that requests a review via legacy API when the view appears.
struct RequestReviewLegacyModifier: ViewModifier {
    /// The eligibility for requesting a review.
    let isEligible: Bool

    /// The closure to execute after requesting a review.
    let afterClosure: () -> Void

    func body(content: Content) -> some View {
        content
            .task(id: isEligible) {
                if isEligible {
                    SKStoreReviewController.requestReview()
                    afterClosure()
                }
            }
    }
}
