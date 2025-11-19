// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared

class MasterPasswordGeneratorViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<
        MasterPasswordGeneratorState,
        MasterPasswordGeneratorAction,
        MasterPasswordGeneratorEffect,
    >!
    var subject: MasterPasswordGeneratorView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        let state = MasterPasswordGeneratorState(generatedPassword: "Imma-Little-Teapot2")
        processor = MockProcessor(state: state)
        subject = MasterPasswordGeneratorView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the generate button performs the `.generate` effect.
    @MainActor
    func test_generateButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.generate)
        try await button.tap()
        waitFor(!processor.effects.isEmpty)
        XCTAssertEqual(processor.effects.last, .generate)
    }

    /// Tapping the prevent account lock button dispatches the `.preventAccountLock` action.
    @MainActor
    func test_preventAccountLockButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.learnAboutOtherWaysToPreventAccountLockout)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .preventAccountLock)
    }

    /// Tapping the save button dispatches the `.save` action.
    @MainActor
    func test_saveButton_tap() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-26079 Remove when toolbar AsyncButton is used.
            throw XCTSkip("Remove this when the toolbar save button gets updated to use AsyncButton.")
        }

        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .save)
    }
}
