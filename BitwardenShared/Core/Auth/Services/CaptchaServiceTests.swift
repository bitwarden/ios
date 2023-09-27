import XCTest

@testable import BitwardenShared

// MARK: - CaptchaServiceTests

class CaptchaServiceTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DefaultCaptchaService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = DefaultCaptchaService(
            baseUrlService: DefaultBaseUrlService(baseUrl: .example),
            callbackUrlScheme: "example"
        )
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    func test_callbackUrlScheme() {
        XCTAssertEqual(subject.callbackUrlScheme, "example")
    }

    func test_generateCaptchaUrl() throws {
        let url = try subject.generateCaptchaUrl(with: "12345")

        var correctUrlComponents = URLComponents(string: "https://example.com/captcha-mobile-connector.html")
        correctUrlComponents?.queryItems = [
            URLQueryItem(
                name: "data",
                value: "eyJsb2NhbGUiOiJlbiIsImNhbGxiYWNrVXJpIjoiZXhhbXBsZTpcL1wvY2FwdGNoYS1jYWxsYmFjayIsInNpdGVLZXkiOiIxMjM0NSIsImNhcHRjaGFSZXF1aXJlZFRleHQiOiJDYXB0Y2hhIHJlcXVpcmVkIn0="
            ),
            URLQueryItem(name: "parent", value: "example://captcha-callback"),
            URLQueryItem(name: "v", value: "1"),
        ]
        XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false), correctUrlComponents)
    }
}
