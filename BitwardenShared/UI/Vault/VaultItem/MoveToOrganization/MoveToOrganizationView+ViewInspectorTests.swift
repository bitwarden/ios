// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenShared

class MoveToOrganizationViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<MoveToOrganizationState, MoveToOrganizationAction, MoveToOrganizationEffect>!
    var subject: MoveToOrganizationView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: MoveToOrganizationState(cipher: .fixture()))
        let store = Store(processor: processor)

        subject = MoveToOrganizationView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the move button dispatches the `.dismissPressed` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the move button dispatches the `.moveCipher` action when the `vfo1-foundation`
    /// feature flag is disabled.
    @MainActor
    func test_moveButton_tap_vfo1FoundationDisabled() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.move)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .moveCipher)
    }

    /// Tapping the move button dispatches the `.moveCipher` action when the `vfo1-foundation`
    /// feature flag is enabled.
    @MainActor
    func test_moveButton_tap_vfo1FoundationEnabled() async throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-26079 Remove when toolbar AsyncButton is used.
            throw XCTSkip("Remove this when the toolbar move button gets updated to use AsyncButton.")
        }

        processor.state.isVfo1FoundationFeatureFlagEnabled = true

        let button = try subject.inspect().find(asyncButton: Localizations.move)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .moveCipher)
    }

    /// Updating the organization menu owner dispatches the `.ownerChanged()` action when the
    /// `vfo1-foundation` feature flag is disabled.
    @MainActor
    func test_organizationMenu_ownerChanged_vfo1FoundationDisabled() throws {
        processor.state.ownershipOptions = [.organization(id: "1", name: "Organization")]
        processor.state.owner = CipherOwner.organization(id: "1", name: "Organization")

        let owner = CipherOwner.organization(id: "2", name: "Bitwarden")
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.organization)
        try menuField.select(newValue: owner)
        XCTAssertEqual(processor.dispatchedActions.last, .ownerChanged(owner))
    }

    /// Updating the organization menu owner dispatches the `.ownerChanged()` action when the
    /// `vfo1-foundation` feature flag is enabled.
    @MainActor
    func test_organizationMenu_ownerChanged_vfo1FoundationEnabled() throws {
        processor.state.isVfo1FoundationFeatureFlagEnabled = true
        processor.state.ownershipOptions = [.organization(id: "1", name: "Organization")]
        processor.state.owner = CipherOwner.organization(id: "1", name: "Organization")

        let owner = CipherOwner.organization(id: "2", name: "Bitwarden")
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.vault)
        try menuField.select(newValue: owner)
        XCTAssertEqual(processor.dispatchedActions.last, .ownerChanged(owner))
    }
}
