#if compiler(>=6.0.3)
import AuthenticationServices
#endif
import XCTest

@testable import BitwardenShared

// MARK: - CredentialManagerFactoryTests

@available(iOS 18.2, *)
class CredentialManagerFactoryTests: BitwardenTestCase {
    // MARK: Properties

    var subject: CredentialManagerFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DefaultCredentialManagerFactory()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `createExportManager(presentationAnchor:)` creates an instance of the credential export manager.
    @MainActor
    func test_createExportManager() {
        let manager = subject.createExportManager(presentationAnchor: UIWindow())

        XCTAssertTrue(manager is ASCredentialExportManager)
    }

    /// `createImportManager()` creates an instance of the credential import manager.
    func test_createImportManager() {
        let manager = subject.createImportManager()

        XCTAssertTrue(manager is ASCredentialImportManager)
    }
}
