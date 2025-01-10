import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - SetUpTwoFactorViewTests

class SetUpTwoFactorViewTests: BitwardenTestCase {
    // MARK: Types

    /// Wraps the add/edit send view in a navigation controller with the hairline divider removed
    /// for snapshot tests.
    struct SnapshotView: UIViewControllerRepresentable {
        let subject: SetUpTwoFactorView

        func makeUIViewController(context: Context) -> some UIViewController {
            let viewController = UIHostingController(rootView: subject)
            let navigationController = UINavigationController(rootViewController: viewController)
            return navigationController
        }

        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    }

    // MARK: Properties

    var processor: MockProcessor<SetUpTwoFactorState, SetUpTwoFactorAction, SetUpTwoFactorEffect>!
    var subject: SetUpTwoFactorView!

    @MainActor var snapshotView: some View {
        SnapshotView(subject: subject).edgesIgnoringSafeArea(.all)
    }

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SetUpTwoFactorState(allowDelay: true, emailAddress: "person@example.com"))
        let store = Store(processor: processor)

        subject = SetUpTwoFactorView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the change email button sends `.changeAccountEmailTapped`
    @MainActor
    func test_changeEmail_tap() throws {
        let button = try subject.inspect().find(button: Localizations.changeAccountEmail)
        try button.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .changeAccountEmailTapped)
    }

    /// Tapping the remind me later button sends `.remindMeLater`
    @MainActor
    func test_remindMeLater_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.remindMeLater)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .remindMeLaterTapped)
    }

    /// Tapping the turn on two-step login button sends `.turnOnTwoFactorTapped`
    @MainActor
    func test_turnOnTwoStep_tap() throws {
        let button = try subject.inspect().find(button: Localizations.turnOnTwoStepLogin)
        try button.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .turnOnTwoFactorTapped)
    }

    // MARK: Previews

    /// The set up two factor view renders correctly when delay is allowed
    @MainActor
    func test_snapshot_setUpTwoFactorView_allowDelay_true() {
        processor.state.allowDelay = true
        assertSnapshots(
            of: snapshotView,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5, .defaultLandscape]
        )
    }

    /// The set up two factor view renders correctly when delay is allowed
    @MainActor
    func test_snapshot_setUpTwoFactorView_allowDelay_false() {
        processor.state.allowDelay = false
        assertSnapshots(
            of: snapshotView,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5, .defaultLandscape]
        )
    }
}
