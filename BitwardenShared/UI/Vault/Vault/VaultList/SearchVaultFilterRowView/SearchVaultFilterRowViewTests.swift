import BitwardenSdk
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - SearchVaultFilterRowViewTests

class SearchVaultFilterRowViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SearchVaultFilterRowState, SearchVaultFilterRowAction, Void>!
    var subject: SearchVaultFilterRowView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: SearchVaultFilterRowState(organizations: [.fixture(name: "org1")]))
        let store = Store(processor: processor)
        subject = SearchVaultFilterRowView(
            hasDivider: true,
            store: store
        )
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Selecting the search vault filter option dispatches the `.searchVaultFilterChanged` action.
    func test_vaultFilterOption_tap() throws {
        let picker = try subject.inspect().find(ViewType.Picker.self)
        try picker.select(value: VaultFilterType.myVault)
        XCTAssertEqual(processor.dispatchedActions.last, .searchVaultFilterChanged(.myVault))
        let org = Organization.fixture(name: "org1")
        try picker.select(value: VaultFilterType.organization(org))
        XCTAssertEqual(processor.dispatchedActions.last, .searchVaultFilterChanged(.organization(org)))
    }
}
