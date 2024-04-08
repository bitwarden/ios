import XCTest

@testable import BitwardenShared

class LoginWithDeviceRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: LoginWithDeviceRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = LoginWithDeviceRequest(
            body: LoginWithDeviceRequestModel(
                email: "email",
                publicKey: "public key",
                deviceIdentifier: "device identifier",
                accessCode: "access code",
                type: AuthRequestType.authenticateAndUnlock,
                fingerprintPhrase: "fingerprint phrase"
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` is the JSON encoded request model.
    func test_body() throws {
        let bodyData = try XCTUnwrap(subject.body?.encode())
        XCTAssertEqual(
            bodyData.prettyPrintedJson,
            """
            {
              "accessCode" : "access code",
              "deviceIdentifier" : "device identifier",
              "email" : "email",
              "fingerprintPhrase" : "fingerprint phrase",
              "publicKey" : "public key",
              "type" : 0
            }
            """
        )
    }

    /// `headers` contains the device device identifier header.
    func test_headers() {
        XCTAssertEqual(subject.headers, ["Device-Identifier": "device identifier"])
    }

    /// `method` is `.post`.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` is the correct value.
    func test_path() {
        XCTAssertEqual(subject.path, "/auth-requests")
    }
}
