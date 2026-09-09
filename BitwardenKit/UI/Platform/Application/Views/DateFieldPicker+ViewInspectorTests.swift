// swiftlint:disable:this file_name
import BitwardenResources
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenKit

private extension InspectableView where View == ViewType.DatePicker {
    /// Locates the raw binding on this date picker's selection value. Can be used to read the
    /// currently displayed selection.
    func selectionBinding() throws -> Binding<Date> {
        let mirror = Mirror(reflecting: self)
        if let binding = mirror.descendant("content", "view", "_selection") as? Binding<Date> {
            return binding
        } else {
            throw InspectionError.attributeNotFound(
                label: "_selection",
                type: String(describing: ViewType.DatePicker.self),
            )
        }
    }
}

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

    /// Picking a day on the live `DatePicker` (in its local-day domain) converts it back into the
    /// UTC-anchored form used for storage.
    func test_commitSelectedLocalDay_commitsUTCAnchoredDate() throws {
        subject = DateFieldPicker(
            title: "Date of birth",
            date: bindingDate,
            defaultDate: defaultDate,
            isExpanded: true,
        )
        let pickedLocalDay = Date(year: 2024, month: 2, day: 29)
        try subject.inspect().find(ViewType.DatePicker.self).select(date: pickedLocalDay)
        XCTAssertEqual(date, pickedLocalDay.asUTCCalendarDay())
    }

    /// Selecting the day that's already displayed is idempotent: it doesn't drift the stored date by
    /// re-converting an already-converted value.
    func test_commitSelectedLocalDay_isIdempotentForTheCurrentlyDisplayedDay() throws {
        date = Date(year: 2024, month: 2, day: 29)
        subject = DateFieldPicker(
            title: "Date of birth",
            date: bindingDate,
            defaultDate: defaultDate,
            isExpanded: true,
        )
        let datePicker = try subject.inspect().find(ViewType.DatePicker.self)
        let displayedDay = try datePicker.selectionBinding().wrappedValue
        try datePicker.select(date: displayedDay)
        XCTAssertEqual(date, Date(year: 2024, month: 2, day: 29))
    }

    /// A selection change reported by the calendar's quick month/year navigation header — a new
    /// month/year, before any day has been tapped — still commits, so the field's value stays in sync
    /// with whatever the calendar is currently showing. A day tapped afterward, within that newly
    /// navigated month, also commits normally.
    func test_handleSelectionChange_navigateThenPickDay_bothCommit() throws {
        date = Date(year: 2024, month: 2, day: 29)
        subject = DateFieldPicker(
            title: "Date of birth",
            date: bindingDate,
            defaultDate: defaultDate,
            isExpanded: true,
        )
        let datePicker = try subject.inspect().find(ViewType.DatePicker.self)

        let navigatedMonth = Date(year: 2024, month: 3, day: 29)
        try datePicker.select(date: navigatedMonth)
        XCTAssertEqual(date, navigatedMonth.asUTCCalendarDay())

        let pickedDay = Date(year: 2024, month: 3, day: 15)
        try datePicker.select(date: pickedDay)
        XCTAssertEqual(date, pickedDay.asUTCCalendarDay())
    }

    /// A selection change reporting the exact same day as the currently committed value — the calendar
    /// settling on a newly navigated month, not a new tap — still commits, even though it's a no-op.
    func test_handleSelectionChange_repeatedSameDay_stillCommits() throws {
        let trackedDay = Date(year: 2024, month: 3, day: 1)
        date = trackedDay
        subject = DateFieldPicker(
            title: "Date of birth",
            date: bindingDate,
            defaultDate: defaultDate,
            isExpanded: true,
        )
        try subject.inspect().find(ViewType.DatePicker.self).select(date: trackedDay)
        XCTAssertEqual(date, trackedDay.asUTCCalendarDay())
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

    /// The collapsed header is a button so a single tap expands the picker.
    func test_headerButton_exists() throws {
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "DateFieldPickerHeaderButton"))
    }

    /// The header button carries an accessibility hint telling VoiceOver users that activating it opens
    /// the calendar picker, rather than a generic (and ambiguous-sounding) "Select date".
    func test_headerButton_hasOpensDatePickerHint() throws {
        let header = try subject.inspect().find(viewWithAccessibilityIdentifier: "DateFieldPickerHeaderButton")
        XCTAssertEqual(try header.accessibilityHint().string(), Localizations.opensDatePicker)
    }

    /// Expanding an empty field immediately commits `defaultDate`, matching the day the calendar shows
    /// as already selected, so the user can save without first tapping a different day and back.
    func test_headerButton_expandingEmptyField_commitsDefaultDate() throws {
        let header = try subject.inspect().find(viewWithAccessibilityIdentifier: "DateFieldPickerHeaderButton")
        try header.button().tap()
        XCTAssertEqual(date, defaultDate)
    }

    /// Collapsing an already-expanded field doesn't clear or otherwise touch a previously committed date.
    func test_headerButton_collapsingField_doesNotChangeCommittedDate() throws {
        date = Date(year: 2024, month: 2, day: 29)
        subject = DateFieldPicker(
            title: "Date of birth",
            date: bindingDate,
            defaultDate: defaultDate,
            isExpanded: true,
        )
        let header = try subject.inspect().find(viewWithAccessibilityIdentifier: "DateFieldPickerHeaderButton")
        try header.button().tap()
        XCTAssertEqual(date, Date(year: 2024, month: 2, day: 29))
    }

    /// The `DatePicker`'s displayed selection converts the stored UTC-anchored date into the local
    /// calendar day domain the `DatePicker` operates in.
    func test_selectedLocalDay_convertsStoredDateToLocalDay() throws {
        let stored = Date(year: 2024, month: 2, day: 29)
        date = stored
        subject = DateFieldPicker(
            title: "Date of birth",
            date: bindingDate,
            defaultDate: defaultDate,
            isExpanded: true,
        )
        let displayedDay = try subject.inspect().find(ViewType.DatePicker.self).selectionBinding().wrappedValue
        XCTAssertEqual(displayedDay, stored.asLocalCalendarDay())
    }

    /// The `DatePicker`'s displayed selection falls back to `defaultDate` when no date is set yet.
    func test_selectedLocalDay_fallsBackToDefaultDateWhenUnset() throws {
        date = nil
        subject = DateFieldPicker(
            title: "Date of birth",
            date: bindingDate,
            defaultDate: defaultDate,
            isExpanded: true,
        )
        let displayedDay = try subject.inspect().find(ViewType.DatePicker.self).selectionBinding().wrappedValue
        XCTAssertEqual(displayedDay, defaultDate.asLocalCalendarDay())
    }
}
