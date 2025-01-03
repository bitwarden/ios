import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

class BitwardenSegmentedControlTests: BitwardenTestCase {
    // MARK: Types

    enum Segment: Int, CaseIterable, Identifiable, Menuable {
        case one = 1, two, three

        var id: Int { rawValue }

        var localizedName: String {
            switch self {
            case .one: "One"
            case .two: "Two"
            case .three: "Three"
            }
        }
    }

    // MARK: Tests

    /// Tapping on a segment changes the selection.
    func test_selectionChanged() throws {
        var selection = Segment.one
        let subject = BitwardenSegmentedControl(
            selection: Binding(get: { selection }, set: { selection = $0 }),
            selections: Segment.allCases
        )

        let buttonTwo = try subject.inspect().find(button: "Two")
        try buttonTwo.tap()
        XCTAssertEqual(selection, .two)

        let buttonThree = try subject.inspect().find(button: "Three")
        try buttonThree.tap()
        XCTAssertEqual(selection, .three)
    }
}
