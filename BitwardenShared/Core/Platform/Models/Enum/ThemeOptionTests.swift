import UIKit
import XCTest

@testable import BitwardenShared

class ThemeOptionTests: BitwardenTestCase {
    // MARK: Tests

    /// `init` returns the expected values.
    func test_init() {
        XCTAssertEqual(ThemeOption("dark"), .dark)
        XCTAssertEqual(ThemeOption(nil), .default)
        XCTAssertEqual(ThemeOption("light"), .light)
        XCTAssertEqual(ThemeOption("gibberish"), .default)
    }

    /// `statusBarStyle` has the expected values.
    func test_statusBarStyle() {
        XCTAssertEqual(ThemeOption.dark.statusBarStyle, .lightContent)
        XCTAssertEqual(ThemeOption.default.statusBarStyle, .default)
        XCTAssertEqual(ThemeOption.light.statusBarStyle, .darkContent)
    }

    /// `title` has the expected values.
    func test_title() {
        XCTAssertEqual(ThemeOption.dark.title, Localizations.dark)
        XCTAssertEqual(ThemeOption.default.title, Localizations.defaultSystem)
        XCTAssertEqual(ThemeOption.light.title, Localizations.light)
    }

    /// `userInterfaceStyle` has the expected values.
    func test_userInterfaceStyle() {
        XCTAssertEqual(ThemeOption.dark.userInterfaceStyle, .dark)
        XCTAssertEqual(ThemeOption.default.userInterfaceStyle, .unspecified)
        XCTAssertEqual(ThemeOption.light.userInterfaceStyle, .light)
    }

    /// `value` has the expected values.
    func test_value() {
        XCTAssertEqual(ThemeOption.dark.value, "dark")
        XCTAssertNil(ThemeOption.default.value)
        XCTAssertEqual(ThemeOption.light.value, "light")
    }
}
