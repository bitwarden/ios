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
        let expected = defaultDate.longCalendarDateDisplay
        XCTAssertNoThrow(try subject.inspect().find(text: expected))
    }

    /// The collapsed header is a button so a single tap expands the picker.
    func test_headerButton_exists() throws {
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "DateFieldPickerHeaderButton"))
    }

    /// The header button carries an accessibility hint telling VoiceOver users it selects a date.
    func test_headerButton_hasSelectDateHint() throws {
        let header = try subject.inspect().find(viewWithAccessibilityIdentifier: "DateFieldPickerHeaderButton")
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
        let clearButton = try subject.inspect().find(viewWithAccessibilityIdentifier: "DateFieldPickerClearButton")
        try clearButton.button().tap()
        XCTAssertNil(date)
    }

    /// No clear control is shown when the field is empty.
    func test_clearButton_hiddenWhenEmpty() throws {
        XCTAssertThrowsError(try subject.inspect().find(viewWithAccessibilityIdentifier: "DateFieldPickerClearButton"))
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

    /// The header and clear button identifiers derive from a custom accessibility identifier, so
    /// multiple pickers on the same screen (each given a distinct identifier) don't share child
    /// element identifiers.
    func test_accessibilityIdentifier_custom_derivesChildIdentifiers() throws {
        date = defaultDate
        subject = DateFieldPicker(
            title: "Date of birth",
            accessibilityIdentifier: "DateOfBirthField",
            date: bindingDate,
            defaultDate: defaultDate,
        )
        XCTAssertNoThrow(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "DateOfBirthFieldHeaderButton"),
        )
        XCTAssertNoThrow(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "DateOfBirthFieldClearButton"),
        )
    }

    /// `selectedLocalDay()` (which feeds the `DatePicker`'s displayed selection) converts the stored
    /// UTC-anchored date into the local calendar day domain the `DatePicker` operates in.
    func test_selectedLocalDay_convertsStoredDateToLocalDay() {
        let stored = Date(year: 2024, month: 2, day: 29)
        date = stored
        XCTAssertEqual(subject.selectedLocalDay(), stored.asLocalCalendarDay())
    }

    /// `selectedLocalDay()` falls back to `defaultDate` when no date is set yet.
    func test_selectedLocalDay_fallsBackToDefaultDateWhenUnset() {
        date = nil
        XCTAssertEqual(subject.selectedLocalDay(), defaultDate.asLocalCalendarDay())
    }

    /// `commitSelectedLocalDay(_:)` (called when the user picks a day on the `DatePicker`) converts
    /// the picked local calendar day back into the UTC-anchored form used for storage — the exact
    /// composition `selection()` wires into the live `DatePicker`, verified here without needing to
    /// render or expand the calendar.
    func test_commitSelectedLocalDay_commitsUTCAnchoredDate() {
        let pickedLocalDay = Date(year: 2024, month: 2, day: 29)
        subject.commitSelectedLocalDay(pickedLocalDay)
        XCTAssertEqual(date, pickedLocalDay.asUTCCalendarDay())
    }

    /// Selecting the day that's already displayed is idempotent: it doesn't drift the stored date by
    /// re-converting an already-converted value.
    func test_commitSelectedLocalDay_isIdempotentForTheCurrentlyDisplayedDay() {
        date = Date(year: 2024, month: 2, day: 29)
        subject.commitSelectedLocalDay(subject.selectedLocalDay())
        XCTAssertEqual(date, Date(year: 2024, month: 2, day: 29))
    }
}
