// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

class GeneratorViewTests: BitwardenTestCase {
    // MARK: Types

    /// Wraps the generator view in a navigation controller with the hairline divider removed for
    /// snapshot tests.
    struct SnapshotView: UIViewControllerRepresentable {
        let subject: GeneratorView

        func makeUIViewController(context: Context) -> some UIViewController {
            let viewController = UIHostingController(rootView: subject)
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.prefersLargeTitles = true
            navigationController.removeHairlineDivider()
            return navigationController
        }

        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    }

    // MARK: Properties

    var processor: MockProcessor<GeneratorState, GeneratorAction, GeneratorEffect>!
    var subject: GeneratorView!

    var snapshotView: some View {
        SnapshotView(subject: subject).edgesIgnoringSafeArea(.all)
    }

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: GeneratorState())
        let store = Store(processor: processor)

        subject = GeneratorView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// Test a snapshot of the copied value toast.
    @MainActor
    func disabletest_snapshot_generatorViewToast() {
        processor.state.generatedValue = "pa11w0rd"
        processor.state.showCopiedValueToast()
        assertSnapshot(
            of: snapshotView,
            as: .defaultPortrait,
        )
    }

    /// Test a snapshot of the passphrase generation view.
    @MainActor
    func disabletest_snapshot_generatorViewPassphrase() {
        processor.state.generatorType = .passphrase
        assertSnapshots(
            of: snapshotView,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot of the password generation view.
    @MainActor
    func disabletest_snapshot_generatorViewPassword() {
        processor.state.generatorType = .password
        assertSnapshots(
            of: snapshotView,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot of the password generation view with the select button.
    @MainActor
    func disabletest_snapshot_generatorViewPassword_inPlace() {
        processor.state.generatorType = .password
        processor.state.presentationMode = .inPlace
        assertSnapshot(of: snapshotView, as: .tallPortrait)
    }

    /// Test a snapshot of the password generation view with a policy in effect.
    @MainActor
    func disabletest_snapshot_generatorViewPassword_policyInEffect() {
        processor.state.isPolicyInEffect = true
        processor.state.policyOptions = PasswordGenerationOptions(type: .password, overridePasswordType: true)
        assertSnapshot(
            of: snapshotView,
            as: .defaultPortrait,
        )
    }

    /// Test a snapshot of the catch-all username generation view.
    @MainActor
    func disabletest_snapshot_generatorViewUsernameCatchAll() {
        processor.state.generatorType = .username
        processor.state.usernameState.usernameGeneratorType = .catchAllEmail
        assertSnapshots(
            of: snapshotView,
            as: [
                Snapshotting.portrait(drawHierarchyInKeyWindow: true),
                Snapshotting.portraitDark(drawHierarchyInKeyWindow: true),
                Snapshotting.tallPortraitAX5(heightMultiple: 1.5, drawHierarchyInKeyWindow: true),
            ],
        )
    }

    /// Test a snapshot of the forwarded email alias generation view.
    @MainActor
    func disabletest_snapshot_generatorViewUsernameForwarded() {
        processor.state.generatorType = .username
        processor.state.usernameState.usernameGeneratorType = .forwardedEmail
        assertSnapshot(
            of: snapshotView,
            as: .defaultPortrait,
        )
    }

    /// Test a snapshot of the plus addressed username generation view.
    @MainActor
    func disabletest_snapshot_generatorViewUsernamePlusAddressed() {
        processor.state.generatorType = .username
        processor.state.usernameState.usernameGeneratorType = .plusAddressedEmail
        assertSnapshot(
            of: snapshotView,
            as: .defaultPortrait,
        )
    }

    /// Test a snapshot of the plus addressed username generation view with the select button.
    @MainActor
    func disabletest_snapshot_generatorViewUsernamePlusAddressed_inPlace() {
        processor.state.generatorType = .username
        processor.state.usernameState.usernameGeneratorType = .plusAddressedEmail
        processor.state.presentationMode = .inPlace
        assertSnapshot(of: snapshotView, as: .defaultPortrait)
    }

    /// Test a snapshot of the random word username generation view.
    @MainActor
    func disabletest_snapshot_generatorViewUsernameRandomWord() {
        processor.state.generatorType = .username
        processor.state.usernameState.usernameGeneratorType = .randomWord
        assertSnapshot(
            of: snapshotView,
            as: .defaultPortrait,
        )
    }

    /// Tests the snapshot with the learn generator action card.
    @MainActor
    func disabletest_snapshot_generatorView_learnGeneratorActionCard() throws {
        processor.state.isLearnGeneratorActionCardEligible = true
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark],
        )
    }
}
