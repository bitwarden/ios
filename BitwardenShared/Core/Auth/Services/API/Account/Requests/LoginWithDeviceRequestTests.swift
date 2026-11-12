import Foundation
import Testing

@testable import BitwardenShared

// MARK: - LoginWithDeviceRequestTests

struct LoginWithDeviceRequestTests {
    // MARK: Properties

    let subject: LoginWithDeviceRequest

    // MARK: Initialization

    init() {
        subject = Self.makeSubject(type: .authenticateAndUnlock)
    }

    // MARK: Helpers

    /// Creates a `LoginWithDeviceRequest` for the specified auth request type.
    ///
    /// - Parameter type: The type of auth request.
    /// - Returns: A `LoginWithDeviceRequest` for testing.
    ///
    private static func makeSubject(type: AuthRequestType) -> LoginWithDeviceRequest {
        LoginWithDeviceRequest(
            body: LoginWithDeviceRequestModel(
                email: "email",
                publicKey: "public key",
                deviceIdentifier: "device identifier",
                accessCode: "access code",
                type: type,
                fingerprintPhrase: "fingerprint phrase",
            ),
        )
    }

    // MARK: Tests

    /// `body` is the JSON encoded request model.
    @Test
    func body() throws {
        let bodyData = try #require(try subject.body?.encode())
        #expect(
            bodyData.prettyPrintedJson ==
                """
                {
                  "accessCode" : "access code",
                  "deviceIdentifier" : "device identifier",
                  "email" : "email",
                  "fingerprintPhrase" : "fingerprint phrase",
                  "publicKey" : "public key",
                  "type" : 0
                }
                """,
        )
    }

    /// `headers` contains the device identifier header.
    @Test
    func headers() {
        #expect(subject.headers == ["Device-Identifier": "device identifier"])
    }

    /// `headers` contains the device identifier header for admin approval requests.
    @Test
    func headers_adminApproval() {
        let subject = Self.makeSubject(type: .adminApproval)
        #expect(subject.headers == ["Device-Identifier": "device identifier"])
    }

    /// `method` is `.post`.
    @Test
    func method() {
        #expect(subject.method == .post)
    }

    /// `path` is the correct value.
    @Test
    func path() {
        #expect(subject.path == "/auth-requests")
    }

    /// `path` is the admin request path for admin approval requests.
    @Test
    func path_adminApproval() {
        let subject = Self.makeSubject(type: .adminApproval)
        #expect(subject.path == "/auth-requests/admin-request")
    }
}
