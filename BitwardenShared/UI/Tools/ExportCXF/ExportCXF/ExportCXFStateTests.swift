import BitwardenResources
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
        XCTAssertFalse(subject.showMainButton)
        XCTAssertEqual(subject.status, .start)
        XCTAssertFalse(subject.isFeatureUnavailable)
    }

    /// `getter:mainButtonTitle` gets the main button title depending on the status.
    func test_mainButtonTitle() {
        subject.status = .start
        XCTAssertEqual(subject.mainButtonTitle, "")

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

    /// `getter:showMainButton` gets whether to show the main button.
    func test_showMainButton_featureAvailable() {
        subject.status = .start
        XCTAssertFalse(subject.showMainButton)

        subject.status = .prepared(itemsToExport: [])
        XCTAssertTrue(subject.showMainButton)

        subject.status = .failure(message: "")
        XCTAssertTrue(subject.showMainButton)
    }

    /// `getter:showMainButton` returns `false` when feature is unavailable.
    func test_showMainButton_featureUnavailable() {
        subject.isFeatureUnavailable = true
        subject.status = .start
        XCTAssertFalse(subject.showMainButton)

        subject.status = .prepared(itemsToExport: [])
        XCTAssertFalse(subject.showMainButton)

        subject.status = .failure(message: "")
        XCTAssertFalse(subject.showMainButton)
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
