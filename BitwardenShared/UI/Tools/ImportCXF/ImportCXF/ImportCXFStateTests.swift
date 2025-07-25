import BitwardenResources
import XCTest

@testable import BitwardenShared

// MARK: - ImportCXFStateTests

class ImportCXFStateTests: BitwardenTestCase {
    // MARK: Properties

    var subject: ImportCXFState!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = ImportCXFState()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `getter:mainButtonTitle` returns the appropriate value depending on the `status`.
    func test_mainButtonTitle() {
        subject.status = .start
        XCTAssertEqual(subject.mainButtonTitle, Localizations.continue)

        subject.status = .importing
        XCTAssertEqual(subject.mainButtonTitle, "")

        subject.status = .success(totalImportedCredentials: 1, importedResults: [])
        XCTAssertEqual(subject.mainButtonTitle, Localizations.showVault)

        subject.status = .failure(message: "")
        XCTAssertEqual(subject.mainButtonTitle, Localizations.retryImport)
    }

    /// `getter:mainIcon` returns the appropriate value depending on the `status`.
    func test_mainIcon() {
        subject.status = .start
        XCTAssertEqual(subject.mainIcon.name, Asset.Images.fileUpload24.name)

        subject.status = .importing
        XCTAssertEqual(subject.mainIcon.name, Asset.Images.fileUpload24.name)

        subject.status = .success(totalImportedCredentials: 1, importedResults: [])
        XCTAssertEqual(subject.mainIcon.name, Asset.Images.checkCircle24.name)

        subject.status = .failure(message: "")
        XCTAssertEqual(subject.mainIcon.name, Asset.Images.circleX16.name)
    }

    /// `getter:message` returns the appropriate value depending on the `status`.
    func test_message() {
        subject.status = .start
        XCTAssertEqual(subject.message, Localizations.startImportCXFDescriptionLong)

        subject.status = .importing
        XCTAssertEqual(subject.message, Localizations.pleaseDoNotCloseTheApp)

        subject.status = .success(totalImportedCredentials: 1, importedResults: [])
        XCTAssertEqual(subject.message, Localizations.itemsSuccessfullyImported(1))

        subject.status = .failure(message: "Something went wrong")
        XCTAssertEqual(subject.message, "Something went wrong")
    }

    /// `getter:title` returns the appropriate value depending on the `status`.
    func test_title() {
        subject.status = .start
        XCTAssertEqual(subject.title, Localizations.importPasswords)

        subject.status = .importing
        XCTAssertEqual(subject.title, Localizations.importingEllipsis)

        subject.status = .success(totalImportedCredentials: 1, importedResults: [])
        XCTAssertEqual(subject.title, Localizations.importSuccessful)

        subject.status = .failure(message: "Something went wrong")
        XCTAssertEqual(subject.title, Localizations.importFailed)

        subject.isFeatureUnavailable = true
        XCTAssertEqual(subject.title, Localizations.importNotAvailable)
    }

    /// `getter:showCancelButton` returns the appropriate value depending on the `status`.
    func test_showCancelButton() {
        subject.status = .start
        XCTAssertTrue(subject.showCancelButton)

        subject.status = .importing
        XCTAssertFalse(subject.showCancelButton)

        subject.status = .success(totalImportedCredentials: 1, importedResults: [])
        XCTAssertFalse(subject.showCancelButton)

        subject.status = .failure(message: "Something went wrong")
        XCTAssertTrue(subject.showCancelButton)
    }

    /// `getter:showMainButton` returns the appropriate value depending on the `status`.
    func test_showMainButton() {
        subject.status = .start
        XCTAssertTrue(subject.showMainButton)

        subject.status = .importing
        XCTAssertFalse(subject.showMainButton)

        subject.status = .success(totalImportedCredentials: 1, importedResults: [])
        XCTAssertTrue(subject.showMainButton)

        subject.status = .failure(message: "Something went wrong")
        XCTAssertTrue(subject.showMainButton)
    }

    /// `getter:showMainButton` returns `false` when feature unavailable.
    func test_showMainButton_featureUnavailable() {
        subject.isFeatureUnavailable = true
        subject.status = .start
        XCTAssertFalse(subject.showMainButton)

        subject.status = .importing
        XCTAssertFalse(subject.showMainButton)

        subject.status = .success(totalImportedCredentials: 1, importedResults: [])
        XCTAssertFalse(subject.showMainButton)

        subject.status = .failure(message: "Something went wrong")
        XCTAssertFalse(subject.showMainButton)
    }
}
