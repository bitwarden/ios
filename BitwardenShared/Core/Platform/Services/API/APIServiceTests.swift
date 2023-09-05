import XCTest

@testable import BitwardenShared
@testable import Networking

class APIServiceTests: BitwardenTestCase {
    var subject: APIService!

    override func setUp() {
        super.setUp()

        subject = APIService()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    /// `init(client:)` sets the default base URLs for the HTTP services.
    func test_init_defaultURLs() {
        let apiServiceBaseURL = subject.apiService.baseURL
        XCTAssertEqual(apiServiceBaseURL, URL(string: "https://vault.bitwarden.com/api")!)

        let eventsServiceBaseURL = subject.eventsService.baseURL
        XCTAssertEqual(eventsServiceBaseURL, URL(string: "https://vault.bitwarden.com/events")!)

        let identityServiceBaseURL = subject.identityService.baseURL
        XCTAssertEqual(identityServiceBaseURL, URL(string: "https://vault.bitwarden.com/identity")!)
    }
}
