// swiftlint:disable:this file_name
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - CardholderNamePickerViewTests

class CardholderNamePickerViewTests: BitwardenTestCase {
    // MARK: Properties

    var cancelledCalled = false
    var noneSelectedCalled = false
    var selectedName: String?
    var subject: CardholderNamePickerView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        cancelledCalled = false
        noneSelectedCalled = false
        selectedName = nil
        subject = CardholderNamePickerView(
            candidates: ["JANE DOE", "DOE CORP"],
            onCancelled: { [weak self] in
                self?.cancelledCalled = true
            },
            onNameSelected: { [weak self] name in
                self?.selectedName = name
            },
            onNoneSelected: { [weak self] in
                self?.noneSelectedCalled = true
            },
        )
    }

    override func tearDown() {
        super.tearDown()
        cancelledCalled = false
        noneSelectedCalled = false
        selectedName = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button invokes `onCancelled` and does not invoke `onNameSelected` or `onNoneSelected`.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertTrue(cancelledCalled)
        XCTAssertNil(selectedName)
        XCTAssertFalse(noneSelectedCalled)
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
        XCTAssertFalse(cancelledCalled)
        XCTAssertFalse(noneSelectedCalled)
    }

    /// Tapping "None of the above" invokes `onNoneSelected` and does not invoke `onNameSelected` or `onCancelled`.
    @MainActor
    func test_noneOfTheAboveButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.noneOfTheAbove)
        try button.tap()
        XCTAssertTrue(noneSelectedCalled)
        XCTAssertNil(selectedName)
        XCTAssertFalse(cancelledCalled)
    }
}
