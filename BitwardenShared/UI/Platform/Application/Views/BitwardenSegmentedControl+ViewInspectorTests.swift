// swiftlint:disable:this file_name
import BitwardenKit
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
        guard #unavailable(iOS 26) else {
            throw XCTSkip("This test requires iOS 18.6 or earlier")
        }
        var selection = Segment.one
        let subject = BitwardenSegmentedControl(
            selection: Binding(get: { selection }, set: { selection = $0 }),
            selections: Segment.allCases,
        )

        let buttonTwo = try subject.inspect().find(button: "Two")
        try buttonTwo.tap()
        XCTAssertEqual(selection, .two)

        let buttonThree = try subject.inspect().find(button: "Three")
        try buttonThree.tap()
        XCTAssertEqual(selection, .three)
    }

    /// Tapping on the selected segment doesn't update the selection binding.
    func test_selectionCurrentTapped() throws {
        guard #unavailable(iOS 26) else {
            throw XCTSkip("This test requires iOS 18.6 or earlier")
        }
        var selection = Segment.one
        var selectionChangedHistory = [Segment]()
        let subject = BitwardenSegmentedControl(
            selection: Binding(
                get: { selection },
                set: { newValue in
                    selection = newValue
                    selectionChangedHistory.append(newValue)
                },
            ),
            selections: Segment.allCases,
        )

        try subject.inspect().find(button: "One").tap()
        XCTAssertEqual(selection, .one)
        XCTAssertTrue(selectionChangedHistory.isEmpty)

        try subject.inspect().find(button: "Two").tap()
        XCTAssertEqual(selection, .two)
        XCTAssertEqual(selectionChangedHistory, [.two])

        try subject.inspect().find(button: "Two").tap()
        XCTAssertEqual(selectionChangedHistory, [.two])
    }
}
