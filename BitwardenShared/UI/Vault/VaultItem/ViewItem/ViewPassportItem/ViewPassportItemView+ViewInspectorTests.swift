// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

class ViewPassportItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<PassportItemState, ViewItemAction, Void>!
    var subject: ViewPassportItemView!

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

    /// Tapping the copy given name button dispatches the copy action.
    @MainActor
    func test_copyGivenNameButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "PassportCopyFirstNameButton",
        ).button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "Bit", field: .givenName))
    }

    /// Tapping the copy surname button dispatches the copy action.
    @MainActor
    func test_copySurnameButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "PassportCopyLastNameButton",
        ).button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "Warden", field: .surname))
    }

    /// Tapping the copy passport number button dispatches the copy action.
    @MainActor
    func test_copyPassportNumberButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "PassportCopyNumberButton",
        ).button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "X12345678", field: .passportNumber))
    }

    /// Tapping the copy national identification number button dispatches the copy action.
    @MainActor
    func test_copyNationalIdentificationNumberButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "PassportCopyNationalIdentificationNumberButton",
        ).button()
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .copyPressed(value: "123456789", field: .nationalIdentificationNumber),
        )
    }

    /// Tapping the passport number visibility toggle dispatches the toggle action.
    @MainActor
    func test_passportNumberVisibilityToggle_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "ShowPassportNumberButton",
        ).button()
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .passportItemAction(.togglePassportNumberVisibilityChanged(true)),
        )
    }

    /// Tapping the national identification number visibility toggle dispatches the toggle action.
    @MainActor
    func test_nationalIdentificationNumberVisibilityToggle_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "ShowPassportNationalIdentificationNumberButton",
        ).button()
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .passportItemAction(.toggleNationalIdentificationNumberVisibilityChanged(true)),
        )
    }

    /// An empty state renders no fields, so the copy and reveal buttons are absent.
    @MainActor
    func test_emptyState_hidesFields() throws {
        initSubject(state: PassportItemState())
        XCTAssertThrowsError(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "PassportCopyFirstNameButton").button(),
        )
        XCTAssertThrowsError(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "ShowPassportNumberButton").button(),
        )
        XCTAssertThrowsError(
            try subject.inspect().find(
                viewWithAccessibilityIdentifier: "ShowPassportNationalIdentificationNumberButton",
            ).button(),
        )
    }

    // MARK: Private

    /// Initializes the subject with the given state.
    ///
    /// - Parameter state: The passport state to render.
    ///
    @MainActor
    func initSubject(state: PassportItemState) {
        processor = MockProcessor(state: state)
        subject = ViewPassportItemView(store: Store(processor: processor))
    }

    /// A fully populated passport state.
    private func populatedState() -> PassportItemState {
        PassportItemState(
            birthPlace: "San Francisco, USA",
            dateOfBirth: "1989-08-01",
            expirationDate: "2029-08-01",
            givenName: "Bit",
            issueDate: "2019-08-01",
            issuingAuthority: "U.S. Department of State",
            issuingCountry: "United States",
            nationalIdentificationNumber: "123456789",
            nationality: "USA",
            passportNumber: "X12345678",
            passportType: "Regular/Tourist",
            sex: "Male",
            surname: "Warden",
        )
    }
}
