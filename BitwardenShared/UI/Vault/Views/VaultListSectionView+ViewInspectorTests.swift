// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenResources
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class VaultListSectionViewTests: BitwardenTestCase {
    // MARK: Properties

    let section = VaultListSection(
        id: "1",
        items: [VaultListItem.fixture()],
        name: "Name",
    )

    // MARK: Tests

    /// When an `isExpanded` binding is provided, the section renders a collapsible header with the
    /// section-scoped accessibility identifier.
    @MainActor
    func test_isExpanded_rendersExpandableHeader() throws {
        let subject = VaultListSectionView(section: section, isExpanded: .constant(true)) { item in
            Text(item.id)
        }

        XCTAssertNoThrow(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "SectionExpandButton_1"),
        )
    }

    /// When no `isExpanded` binding is provided, the section renders a static header without the
    /// collapsible expand button.
    @MainActor
    func test_isExpanded_nil_rendersStaticHeader() throws {
        let subject = VaultListSectionView(section: section) { item in
            Text(item.id)
        }

        XCTAssertThrowsError(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "SectionExpandButton_1"),
        )
    }

    /// When the `isExpanded` binding is `true`, the section's items are rendered.
    @MainActor
    func test_isExpanded_true_showsItems() throws {
        let item = VaultListItem.fixture()
        let section = VaultListSection(id: "1", items: [item], name: "Name")
        let subject = VaultListSectionView(section: section, isExpanded: .constant(true)) { item in
            Text(item.id)
        }

        XCTAssertNoThrow(try subject.inspect().find(text: item.id))
    }

    /// When the `isExpanded` binding is `false`, the section's items are hidden.
    @MainActor
    func test_isExpanded_false_hidesItems() throws {
        let item = VaultListItem.fixture()
        let section = VaultListSection(id: "1", items: [item], name: "Name")
        let subject = VaultListSectionView(section: section, isExpanded: .constant(false)) { item in
            Text(item.id)
        }

        XCTAssertThrowsError(try subject.inspect().find(text: item.id))
    }
}
