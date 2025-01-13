#if compiler(>=6.0.3)
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

    func test_createImportManager() throws {
        guard #available(iOS 18.2, *) else {
            throw XCTSkip("iOS 18.2 is required to run this test.")
        }
        let manager = subject.createImportManager()

        XCTAssertTrue(manager is ASCredentialImportManager)
    }
}
