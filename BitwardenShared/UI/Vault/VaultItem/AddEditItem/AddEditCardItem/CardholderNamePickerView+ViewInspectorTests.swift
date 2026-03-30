// swiftlint:disable:this file_name
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - CardholderNamePickerViewTests

class CardholderNamePickerViewTests: BitwardenTestCase {
    // MARK: Properties

    var selectedName: String?
    var subject: CardholderNamePickerView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        selectedName = nil
        subject = CardholderNamePickerView(
            candidates: ["JANE DOE", "DOE CORP"],
            onNameSelected: { [weak self] name in
                self?.selectedName = name
            },
        )
    }

    override func tearDown() {
        super.tearDown()
        selectedName = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button does not invoke `onNameSelected`.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertNil(selectedName)
    }

    /// Tapping a candidate button invokes `onNameSelected` with the tapped name.
    @MainActor
    func test_candidateButton_tap_firstCandidate() throws {
        let button = try subject.inspect().find(button: "JANE DOE")
        try button.tap()
        XCTAssertEqual(selectedName, "JANE DOE")
    }

    /// Tapping the second candidate button invokes `onNameSelected` with that name.
    @MainActor
    func test_candidateButton_tap_secondCandidate() throws {
        let button = try subject.inspect().find(button: "DOE CORP")
        try button.tap()
        XCTAssertEqual(selectedName, "DOE CORP")
    }
}
