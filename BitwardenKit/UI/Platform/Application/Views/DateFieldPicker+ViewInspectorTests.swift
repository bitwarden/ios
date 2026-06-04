// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenResources
import SwiftUI
import ViewInspector
import XCTest

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
}
