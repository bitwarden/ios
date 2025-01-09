import XCTest

@testable import BitwardenShared

// MARK: - ExportCXFStateTests

class ExportCXFStateTests: BitwardenTestCase {
    // MARK: Properties

    var subject: ExportCXFState!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = ExportCXFState()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `init` should have the desired default values.
    func test_init() {
        XCTAssertTrue(subject.showMainButton)
        XCTAssertEqual(subject.status, .start)
        XCTAssertEqual(subject.totalItemsToExport, 0)
    }

    /// `getter:mainButtonTitle` gets the main button title depending on the status.
    func test_mainButtonTitle() {
        subject.status = .start
        XCTAssertEqual(subject.mainButtonTitle, Localizations.continue)

        subject.status = .prepared(itemsToExport: [])
        XCTAssertEqual(subject.mainButtonTitle, Localizations.exportItems)

        subject.status = .failure(message: "")
        XCTAssertEqual(subject.mainButtonTitle, Localizations.retryExport)
    }

    /// `getter:mainIcon` gets the main icon depending on the status.
    func test_mainIcon() {
        subject.status = .start
        XCTAssertEqual(subject.mainIcon.name, Asset.Images.fileUpload24.name)

        subject.status = .prepared(itemsToExport: [])
        XCTAssertEqual(subject.mainIcon.name, Asset.Images.fileUpload24.name)

        subject.status = .failure(message: "")
        XCTAssertEqual(subject.mainIcon.name, Asset.Images.circleX16.name)
    }

    /// `getter:message` gets the message depending on the status.
    func test_message() {
        subject.status = .start
        XCTAssertEqual(
            subject.message,
            Localizations.exportPasswordsPasskeysCreditCardsAndAnyPersonalIdentityInformation
        )

        subject.status = .prepared(itemsToExport: [])
        XCTAssertEqual(
            subject.message,
            Localizations.exportPasswordsPasskeysCreditCardsAndAnyPersonalIdentityInformation
        )

        subject.status = .failure(message: "Something went wrong")
        XCTAssertEqual(subject.message, "Something went wrong")
    }

    /// `getter:sectionTitle` gets the section title depending on the status.
    func test_sectionTitle() {
        subject.status = .start
        XCTAssertEqual(subject.sectionTitle, Localizations.exportOptions)

        subject.status = .prepared(itemsToExport: [])
        XCTAssertEqual(subject.sectionTitle, Localizations.selectedItems)

        subject.status = .failure(message: "")
        XCTAssertEqual(subject.sectionTitle, "")
    }

    /// `getter:title` gets the title depending on the status.
    func test_title() {
        subject.status = .start
        XCTAssertEqual(subject.title, Localizations.exportItems)

        subject.status = .prepared(itemsToExport: [])
        XCTAssertEqual(subject.title, Localizations.exportItems)

        subject.status = .failure(message: "")
        XCTAssertEqual(subject.title, Localizations.exportFailed)
    }
}
