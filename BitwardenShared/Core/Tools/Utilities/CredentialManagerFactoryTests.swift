#if SUPPORTS_CXP
import AuthenticationServices
#endif
import XCTest

@testable import BitwardenShared

// MARK: - CredentialManagerFactoryTests

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
    func test_createExportManager() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("iOS 26.0 is required to run this test.")
        }
        let manager = subject.createExportManager(presentationAnchor: UIWindow())

        XCTAssertTrue(manager is ASCredentialExportManager)
    }

    /// `createImportManager()` creates an instance of the credential import manager.
    func test_createImportManager() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("iOS 26.0 is required to run this test.")
        }
        let manager = subject.createImportManager()

        XCTAssertTrue(manager is ASCredentialImportManager)
    }
}
