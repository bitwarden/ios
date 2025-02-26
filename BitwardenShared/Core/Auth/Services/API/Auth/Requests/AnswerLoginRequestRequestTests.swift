import Networking
import XCTest

@testable import BitwardenShared

class AnswerLoginRequestRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: AnswerLoginRequestRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = AnswerLoginRequestRequest(
            id: "2",
            requestModel: .init(
                deviceIdentifier: "deviceId",
                key: "key",
                masterPasswordHash: nil,
                requestApproved: true
            )
        )
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `body` returns the body of the request.
    func test_body() throws {
        XCTAssertEqual(subject.body?.deviceIdentifier, "deviceId")
        XCTAssertEqual(subject.body?.key, "key")
        XCTAssertNil(subject.body?.masterPasswordHash)
        XCTAssertTrue(subject.body?.requestApproved == true)
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .put)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/auth-requests/2")
    }
}
