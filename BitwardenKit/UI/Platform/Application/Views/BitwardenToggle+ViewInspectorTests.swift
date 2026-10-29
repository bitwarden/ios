// swiftlint:disable:this file_name
import BitwardenResources
import SwiftUI
import ViewInspector
import ViewInspectorTestHelpers
import XCTest

@testable import BitwardenKit

final class BitwardenToggleTests: BitwardenTestCase {
    // MARK: Tests

    /// The help button's image uses the default accessibility label, which names the custom
    /// accessibility action exposed on the toggle.
    @MainActor
    func test_helpButton_accessibility_defaultLabel() throws {
        let subject = BitwardenToggle(
            isOn: .constant(false),
            helpURL: URL(string: "https://example.com/help")!,
            title: { Text("Toggle") },
        )

        XCTAssertNoThrow(try subject.inspect().find(ViewType.Image.self) { image in
            try image.accessibilityLabel().string() == Localizations.learnMore
        })
    }

    /// The help button's image uses a custom accessibility label when one is provided.
    @MainActor
    func test_helpButton_accessibility_customLabel() throws {
        let subject = BitwardenToggle(
            isOn: .constant(false),
            helpURL: URL(string: "https://example.com/help")!,
            helpAccessibilityLabel: "Help",
            title: { Text("Toggle") },
        )

        XCTAssertNoThrow(try subject.inspect().find(ViewType.Image.self) { image in
            try image.accessibilityLabel().string() == "Help"
        })
    }
}
