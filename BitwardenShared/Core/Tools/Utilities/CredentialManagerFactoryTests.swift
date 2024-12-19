import AuthenticationServices
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

    func test_createImportManager() {
        let manager = subject.createImportManager()

        XCTAssertTrue(manager is ASCredentialImportManager)
    }
}
