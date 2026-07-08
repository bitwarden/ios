// swiftlint:disable:this file_name
import BitwardenResources
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenKit

class DateFieldPickerTests: BitwardenTestCase {
    // MARK: Properties

    /// The default date used to seed the picker when a date is first selected.
    let defaultDate = Date(year: 2023, month: 6, day: 23)

    /// The backing value for the field's date binding.
    var date: Date?

    var subject: DateFieldPicker!

    /// A binding to the test's backing `date` value.
    private var bindingDate: Binding<Date?> {
        Binding {
            self.date
        } set: { newValue in
            self.date = newValue
        }
    }

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        date = nil
        subject = DateFieldPicker(
            title: "Date of birth",
            date: bindingDate,
            defaultDate: defaultDate,
        )
    }

    override func tearDown() {
        super.tearDown()
        date = nil
        subject = nil
    }

    // MARK: Tests

    /// When collapsed and empty, the field shows its title and no inline date picker.
    func test_collapsedEmpty_showsTitleAndNoPicker() throws {
        XCTAssertNoThrow(try subject.inspect().find(text: "Date of birth"))
        XCTAssertThrowsError(try subject.inspect().find(ViewType.DatePicker.self))
    }

    /// When a date is selected, the collapsed field shows the formatted date.
    func test_collapsedSelected_showsFormattedDate() throws {
        date = defaultDate
        let expected = defaultDate.formatted(date: .long, time: .omitted)
        XCTAssertNoThrow(try subject.inspect().find(text: expected))
    }

    /// The collapsed header is a button so a single tap expands the picker.
    func test_headerButton_exists() throws {
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "DateFieldHeaderButton"))
    }

    /// The header button carries an accessibility hint telling VoiceOver users it selects a date.
    func test_headerButton_hasSelectDateHint() throws {
        let header = try subject.inspect().find(viewWithAccessibilityIdentifier: "DateFieldHeaderButton")
        XCTAssertEqual(try header.accessibilityHint().string(), Localizations.selectDate)
    }

    /// The clear control's accessibility label names the field so VoiceOver users know what it clears.
    func test_clearButton_accessibilityLabel_namesField() throws {
        date = defaultDate
        XCTAssertNoThrow(
            try subject.inspect().find(viewWithAccessibilityLabel: Localizations.clearFieldName("Date of birth")),
        )
    }

    /// When a date is selected, a clear control is shown and tapping it resets the value to `nil`.
    func test_clearButton_clearsDate() throws {
        date = defaultDate
        let clearButton = try subject.inspect().find(viewWithAccessibilityIdentifier: "DateFieldClearButton")
        try clearButton.button().tap()
        XCTAssertNil(date)
    }

    /// No clear control is shown when the field is empty.
    func test_clearButton_hiddenWhenEmpty() throws {
        XCTAssertThrowsError(try subject.inspect().find(viewWithAccessibilityIdentifier: "DateFieldClearButton"))
    }

    /// A provided footer is rendered below the field.
    func test_footer_isRendered() throws {
        subject = DateFieldPicker(
            title: "Date of birth",
            date: bindingDate,
            defaultDate: defaultDate,
            footer: "A footer",
        )
        XCTAssertNoThrow(try subject.inspect().find(text: "A footer"))
    }

    /// The field applies the provided accessibility identifier.
    func test_accessibilityIdentifier_custom() throws {
        subject = DateFieldPicker(
            title: "Date of birth",
            accessibilityIdentifier: "DateOfBirthField",
            date: bindingDate,
            defaultDate: defaultDate,
        )
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "DateOfBirthField"))
    }

    /// The wheel picker should be focused when the field is expanded with VoiceOver on.
    func test_shouldFocusPicker_returnsTrue_whenExpandedAndVoiceOverOn() {
        XCTAssertTrue(subject.shouldFocusPicker(isExpanded: true, voiceOverEnabled: true))
    }

    /// The wheel picker should not be focused when the field is expanded without VoiceOver.
    func test_shouldFocusPicker_returnsFalse_whenExpandedAndVoiceOverOff() {
        XCTAssertFalse(subject.shouldFocusPicker(isExpanded: true, voiceOverEnabled: false))
    }

    /// The wheel picker should never be focused when the field is collapsed, regardless of VoiceOver.
    func test_shouldFocusPicker_returnsFalse_whenCollapsed() {
        XCTAssertFalse(subject.shouldFocusPicker(isExpanded: false, voiceOverEnabled: true))
    }
}
