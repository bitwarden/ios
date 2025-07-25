import BitwardenResources
import SnapshotTesting
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
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the move button dispatches the `.moveCipher` action.
    @MainActor
    func test_moveButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.move)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .moveCipher)
    }

    /// Updating the organization menu owner dispatches the `.ownerChanged()` action.
    @MainActor
    func test_organizationMenu_ownerChanged() throws {
        processor.state.ownershipOptions = [.organization(id: "1", name: "Organization")]
        processor.state.owner = CipherOwner.organization(id: "1", name: "Organization")

        let owner = CipherOwner.organization(id: "2", name: "Bitwarden")
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.organization)
        try menuField.select(newValue: owner)
        XCTAssertEqual(processor.dispatchedActions.last, .ownerChanged(owner))
    }

    // MARK: Previews

    /// The empty view renders correctly.
    func test_snapshot_moveToOrganization_empty() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The collections view renders correctly.
    @MainActor
    func test_snapshot_moveToOrganization_collections() {
        processor.state.collections = [
            .fixture(id: "1", name: "Design", organizationId: "1"),
            .fixture(id: "2", name: "Engineering", organizationId: "1"),
        ]
        processor.state.organizationId = "1"
        processor.state.ownershipOptions = [.organization(id: "1", name: "Organization")]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
}
