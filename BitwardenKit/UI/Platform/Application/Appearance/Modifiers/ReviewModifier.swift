import StoreKit
import SwiftUI

/// A view modifier that requests a review when the view appears if eligible.
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

    /// The window scene to request a review.
    let windowScene: UIWindowScene

    /// The closure to execute after requesting a review.
    let afterClosure: () -> Void

    func body(content: Content) -> some View {
        content
            .task(id: isEligible) {
                if isEligible {
                    SKStoreReviewController.requestReview(in: windowScene)
                    afterClosure()
                }
            }
    }
}

/// A view extension that requests a review when the view appears.
public extension View {
    /// A view modifier that requests a review when the view appears.
    /// - Parameters:
    ///   - isEligible: The eligibility for requesting a review.
    ///   - windowScene: The window scene to request a review. This is only used on systems prior to iOS 16.
    ///   - afterClosure: The closure to execute after requesting a review.
    func requestReview(
        isEligible: Bool,
        windowScene: UIWindowScene?,
        afterClosure: @escaping () -> Void,
    ) -> some View {
        apply { view in
            if #available(iOS 16.0, *) {
                view.modifier(
                    ReviewModifier(
                        isEligible: isEligible,
                        afterClosure: afterClosure,
                    ),
                )
            } else {
                if let windowScene {
                    view.modifier(
                        RequestReviewLegacyModifier(
                            isEligible: isEligible,
                            windowScene: windowScene,
                            afterClosure: afterClosure,
                        ),
                    )
                }
            }
        }
    }
}

/// An error that represents a window scene error.
public enum WindowSceneError: Error, Equatable {
    /// The window scene is null.
    case nullWindowScene
}
