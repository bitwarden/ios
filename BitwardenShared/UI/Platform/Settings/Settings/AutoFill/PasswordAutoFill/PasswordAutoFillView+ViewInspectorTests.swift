// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenShared

// MARK: - PasswordAutoFillViewTests

class PasswordAutoFillViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<PasswordAutoFillState, Void, PasswordAutoFillEffect>!
    var subject: PasswordAutoFillView!

    // MARK: Setup & Teardown

    override func setUp() {
        processor = MockProcessor(
            state: PasswordAutoFillState(
                mode: .settings,
            ),
        )
        subject = PasswordAutoFillView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the turn on later button dispatches the `.turnAutoFillOnLaterTapped()` effect.
    @MainActor
    func test_turnOnAutoFillLaterButton_tap() async throws {
        processor.state.mode = .onboarding
        let button = try subject.inspect().find(asyncButton: Localizations.turnOnLater)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .turnAutoFillOnLaterButtonTapped)
    }

    /// The button to turn on later doesn't exist when navigating in settings mode.
    @MainActor
    func test_turnOnAutoFillLaterButton_doesntExist() async throws {
        processor.state.mode = .settings
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.turnOnLater))
    }
}
