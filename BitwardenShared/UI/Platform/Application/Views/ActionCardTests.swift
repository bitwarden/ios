import SwiftUI
import XCTest

@testable import BitwardenShared

final class ActionCardTests: BitwardenTestCase {
    // MARK: Tests

    /// Tapping the action button should call the action button state's action closure.
    func test_actionButton_tap() async throws {
        var actionButtonTapped = false
        let subject = ActionCard(
            title: "Title",
            message: "Message",
            actionButtonState: ActionCard.ButtonState(title: "Tap me!") { actionButtonTapped = true }
        )

        let button = try subject.inspect().find(asyncButton: "Tap me!")
        try await button.tap()

        XCTAssertTrue(actionButtonTapped)
    }

    /// Tapping the dismiss button should call the dismiss button state's action closure.
    func test_dismissButton_tap() async throws {
        var dismissButtonTapped = false
        let subject = ActionCard(
            title: "Title",
            message: "Message",
            dismissButtonState: ActionCard.ButtonState(title: "Dismiss") { dismissButtonTapped = true }
        )

        let button = try subject.inspect().find(asyncButton: "Dismiss")
        try await button.tap()

        XCTAssertTrue(dismissButtonTapped)
    }
}
