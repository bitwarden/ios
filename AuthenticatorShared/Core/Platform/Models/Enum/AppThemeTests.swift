import BitwardenResources
import UIKit
import XCTest

@testable import AuthenticatorShared

class AppThemeTests: BitwardenTestCase {
    // MARK: Tests

    /// `init` returns the expected values.
    func test_init() {
        XCTAssertEqual(AppTheme("dark"), .dark)
        XCTAssertEqual(AppTheme(nil), .default)
        XCTAssertEqual(AppTheme("light"), .light)
        XCTAssertEqual(AppTheme("gibberish"), .default)
    }

    /// `localizedName` has the expected values.
    func test_localizedName() {
        XCTAssertEqual(AppTheme.dark.localizedName, Localizations.dark)
        XCTAssertEqual(AppTheme.default.localizedName, Localizations.defaultSystem)
        XCTAssertEqual(AppTheme.light.localizedName, Localizations.light)
    }

    /// `statusBarStyle` has the expected values.
    func test_statusBarStyle() {
        XCTAssertEqual(AppTheme.dark.statusBarStyle, .lightContent)
        XCTAssertEqual(AppTheme.default.statusBarStyle, .default)
        XCTAssertEqual(AppTheme.light.statusBarStyle, .darkContent)
    }

    /// `userInterfaceStyle` has the expected values.
    func test_userInterfaceStyle() {
        XCTAssertEqual(AppTheme.dark.userInterfaceStyle, .dark)
        XCTAssertEqual(AppTheme.default.userInterfaceStyle, .unspecified)
        XCTAssertEqual(AppTheme.light.userInterfaceStyle, .light)
    }

    /// `value` has the expected values.
    func test_value() {
        XCTAssertEqual(AppTheme.dark.value, "dark")
        XCTAssertNil(AppTheme.default.value)
        XCTAssertEqual(AppTheme.light.value, "light")
    }
}
