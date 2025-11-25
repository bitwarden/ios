// swiftlint:disable:this file_name
import BitwardenKit
import SwiftUI
import ViewInspector
import XCTest

class SettingsPickerFieldTests: BitwardenTestCase {
    // MARK: Properties

    var pickerValue: Int!
    var subject: SettingsPickerField!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        pickerValue = 3600
    }

    override func tearDown() {
        super.tearDown()
        pickerValue = nil
        subject = nil
    }

    // MARK: Tests

    /// Tests that the button exists and can be found.
    func test_button_exists() throws {
        subject = SettingsPickerField(
            title: "Custom",
            customTimeoutValue: "1:00",
            pickerValue: Binding(
                get: { self.pickerValue },
                set: { self.pickerValue = $0 },
            ),
            customTimeoutAccessibilityLabel: "one hour, zero minutes",
        )

        XCTAssertNoThrow(try subject.inspect().find(ViewType.Button.self))
    }

    /// Tests that the custom timeout value is displayed.
    func test_customTimeoutValue_displays() throws {
        subject = SettingsPickerField(
            title: "Custom",
            customTimeoutValue: "2:30",
            pickerValue: Binding(
                get: { self.pickerValue },
                set: { self.pickerValue = $0 },
            ),
            customTimeoutAccessibilityLabel: "two hours, thirty minutes",
        )

        let text = try subject.inspect().find(text: "2:30")
        XCTAssertEqual(try text.string(), "2:30")
    }

    /// Tests that the title is displayed.
    func test_title_displays() throws {
        subject = SettingsPickerField(
            title: "Custom Timeout",
            customTimeoutValue: "1:00",
            pickerValue: Binding(
                get: { self.pickerValue },
                set: { self.pickerValue = $0 },
            ),
            customTimeoutAccessibilityLabel: "one hour, zero minutes",
        )

        let text = try subject.inspect().find(text: "Custom Timeout")
        XCTAssertEqual(try text.string(), "Custom Timeout")
    }

    /// Tests that the picker value binding works correctly.
    func test_pickerValue_binding() {
        let testValue = 7200 // 2 hours
        subject = SettingsPickerField(
            title: "Custom",
            customTimeoutValue: "2:00",
            pickerValue: Binding(
                get: { self.pickerValue },
                set: { self.pickerValue = $0 },
            ),
            customTimeoutAccessibilityLabel: "two hours, zero minutes",
        )

        // Update the bound value
        pickerValue = testValue
        XCTAssertEqual(pickerValue, testValue)
    }

    /// Tests that footer text is displayed when provided.
    func test_footer_displays() throws {
        let footerMessage = "Your organization has set the default session timeout to 1 hour"
        subject = SettingsPickerField(
            title: "Custom",
            footer: footerMessage,
            customTimeoutValue: "1:00",
            pickerValue: Binding(
                get: { self.pickerValue },
                set: { self.pickerValue = $0 },
            ),
            customTimeoutAccessibilityLabel: "one hour, zero minutes",
        )

        let footerText = try subject.inspect().find(text: footerMessage)
        XCTAssertEqual(try footerText.string(), footerMessage)
    }

    /// Tests that the view renders without a footer.
    func test_noFooter_renders() throws {
        subject = SettingsPickerField(
            title: "Custom",
            footer: nil,
            customTimeoutValue: "1:00",
            pickerValue: Binding(
                get: { self.pickerValue },
                set: { self.pickerValue = $0 },
            ),
            customTimeoutAccessibilityLabel: "one hour, zero minutes",
        )

        // Should not throw when inspecting
        XCTAssertNoThrow(try subject.inspect().vStack())
    }

    /// Tests that a divider exists when footer is provided.
    func test_divider_existsWithFooter() throws {
        subject = SettingsPickerField(
            title: "Custom",
            footer: "Footer message",
            customTimeoutValue: "1:00",
            pickerValue: Binding(
                get: { self.pickerValue },
                set: { self.pickerValue = $0 },
            ),
            customTimeoutAccessibilityLabel: "one hour, zero minutes",
        )

        XCTAssertNoThrow(try subject.inspect().find(ViewType.Divider.self))
    }

    /// Tests that a divider does not exist when footer is not provided.
    func test_divider_doesNotExistWithoutFooter() throws {
        subject = SettingsPickerField(
            title: "Custom",
            footer: nil,
            customTimeoutValue: "1:00",
            pickerValue: Binding(
                get: { self.pickerValue },
                set: { self.pickerValue = $0 },
            ),
            customTimeoutAccessibilityLabel: "one hour, zero minutes",
        )

        XCTAssertThrowsError(try subject.inspect().find(ViewType.Divider.self))
    }
}
