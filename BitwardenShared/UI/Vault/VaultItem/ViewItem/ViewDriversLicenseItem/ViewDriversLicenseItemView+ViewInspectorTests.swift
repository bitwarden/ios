// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

class ViewDriversLicenseItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<DriversLicenseItemState, ViewItemAction, Void>!
    var subject: ViewDriversLicenseItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        initSubject(state: populatedState())
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the copy first name button dispatches the copy action.
    @MainActor
    func test_copyFirstNameButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "DriversLicenseCopyFirstNameButton",
        ).button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "Bit", field: .firstName))
    }

    /// Tapping the copy middle name button dispatches the copy action.
    @MainActor
    func test_copyMiddleNameButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "DriversLicenseCopyMiddleNameButton",
        ).button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "W", field: .middleName))
    }

    /// Tapping the copy last name button dispatches the copy action.
    @MainActor
    func test_copyLastNameButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "DriversLicenseCopyLastNameButton",
        ).button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "Warden", field: .lastName))
    }

    /// Tapping the copy license number button dispatches the copy action.
    @MainActor
    func test_copyLicenseNumberButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "DriversLicenseCopyNumberButton",
        ).button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "D1234567", field: .licenseNumber))
    }

    /// Tapping the license number visibility toggle dispatches the toggle action.
    @MainActor
    func test_licenseNumberVisibilityToggle_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "ShowDriversLicenseNumberButton",
        ).button()
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .driversLicenseItemAction(.toggleLicenseNumberVisibilityChanged(true)),
        )
    }

    /// An empty state renders no fields, so the copy buttons are absent.
    @MainActor
    func test_emptyState_hidesFields() throws {
        initSubject(state: DriversLicenseItemState())
        XCTAssertThrowsError(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "DriversLicenseCopyFirstNameButton").button(),
        )
        XCTAssertThrowsError(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "ShowDriversLicenseNumberButton").button(),
        )
    }

    // MARK: Private

    /// Initializes the subject with the given state.
    ///
    /// - Parameter state: The driver's license state to render.
    ///
    @MainActor
    func initSubject(state: DriversLicenseItemState) {
        processor = MockProcessor(state: state)
        subject = ViewDriversLicenseItemView(store: Store(processor: processor))
    }

    /// A fully populated driver's license state.
    private func populatedState() -> DriversLicenseItemState {
        DriversLicenseItemState(
            dateOfBirth: "1989-08-01",
            expirationDate: "2029-08-01",
            firstName: "Bit",
            issueDate: "2019-08-01",
            issuingAuthority: "DMV",
            issuingCountry: "United States",
            issuingState: "California",
            lastName: "Warden",
            licenseClass: "C",
            licenseNumber: "D1234567",
            middleName: "W",
        )
    }
}
