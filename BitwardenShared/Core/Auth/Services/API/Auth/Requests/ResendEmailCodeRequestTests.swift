import Foundation
import Networking
import Testing

@testable import BitwardenShared

// MARK: - ResendEmailCodeRequestTests

struct ResendEmailCodeRequestTests {
    // MARK: Properties

    let subject = ResendEmailCodeRequest(model: .init(
        email: "email",
        masterPasswordHash: nil,
        ssoEmail2FaSessionToken: nil,
    ))

    // MARK: Tests

    /// `body` returns the body of the request.
    @Test
    func body() {
        #expect(subject.body?.email == "email")
        #expect(subject.body?.masterPasswordHash == nil)
        #expect(subject.body?.ssoEmail2FaSessionToken == nil)
    }

    /// `body` encodes to JSON without a device identifier, which is sent in the `Device-Identifier`
    /// header instead.
    @Test
    func body_encoded() throws {
        let bodyData = try #require(try subject.body?.encode())
        #expect(
            bodyData.prettyPrintedJson ==
                """
                {
                  "email" : "email"
                }
                """,
        )
    }

    /// `method` returns the method of the request.
    @Test
    func method() {
        #expect(subject.method == .post)
    }

    /// `path` returns the path of the request.
    @Test
    func path() {
        #expect(subject.path == "/two-factor/send-email-login")
    }
}
