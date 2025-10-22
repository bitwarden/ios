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
}
