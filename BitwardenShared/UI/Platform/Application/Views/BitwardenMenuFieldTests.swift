import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

class BitwardenMenuFieldTests: BitwardenTestCase {
    // MARK: Types

    enum TestValue: String, CaseIterable, Menuable {
        case value1
        case value2

        var localizedName: String {
            rawValue
        }
    }

    // MARK: Properties

    var selection: TestValue!
    var subject: BitwardenMenuField<TestValue>!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        selection = .value1
        let binding = Binding {
            self.selection!
        } set: { newValue in
            self.selection = newValue
        }
        subject = BitwardenMenuField(
            options: TestValue.allCases,
            selection: binding
        )
    }

    override func tearDown() {
        super.tearDown()
        selection = nil
        subject = nil
    }

    // MARK: Tests

    func test_newSelection() throws {
        let picker = try subject.inspect().find(ViewType.Picker.self)
        try picker.select(value: TestValue.value2)
        XCTAssertEqual(selection, .value2)

        let menu = try subject.inspect().find(ViewType.Menu.self)
        let label = try menu.labelView().find(ViewType.Text.self).string()
        XCTAssertEqual(label, "value2")
    }
}
