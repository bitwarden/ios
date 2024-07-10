import AuthenticationServices
import XCTest

@testable import BitwardenShared

@available(iOS 17.0, *)
class Fido2AppExtensionDelegateTests: BitwardenTestCase {
    // MARK: Properties

    var subject: MockFido2AppExtensionDelegate!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = MockFido2AppExtensionDelegate()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `getter:isCreatingFido2Credential`  returns `true`
    /// when there is a request for creation
    func test_isCreatingFido2Credential_true() async throws {
        subject.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        XCTAssertTrue(subject.isCreatingFido2Credential)
    }

    /// `getter:isCreatingFido2Credential`  returns `false`
    /// when there is no request for creation
    func test_isCreatingFido2Credential_false() async throws {
        XCTAssertFalse(subject.isCreatingFido2Credential)
    }
}
