// swiftlint:disable:this file_name
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

final class ExpandableContentTests: BitwardenTestCase {
    // MARK: Tests

    /// The content in the view can be expanded or collapsed by tapping on the button.
    func test_expandToggle() throws {
        var isExpanded = false

        let subject = ExpandableContent(
            title: "Expand",
            isExpanded: Binding(get: { isExpanded }, set: { isExpanded = $0 }),
        ) {
            Text("Content")
        }

        let expandButton = try subject.inspect().find(button: "Expand")

        // Initially collapsed
        XCTAssertThrowsError(try subject.inspect().find(text: "Content"))

        // Expanded
        try expandButton.tap()
        XCTAssertNoThrow(try subject.inspect().find(text: "Content"))

        // Collapsed again
        try expandButton.tap()
        XCTAssertThrowsError(try subject.inspect().find(text: "Content"))
    }
}
