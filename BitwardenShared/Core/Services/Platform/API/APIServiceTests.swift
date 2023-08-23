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
    func testInitDefaultURLs() async {
        let apiServiceBaseURL = await subject.apiService.baseURL
        XCTAssertEqual(apiServiceBaseURL, URL(string: "https://vault.bitwarden.com/api")!)

        let eventsServiceBaseURL = await subject.eventsService.baseURL
        XCTAssertEqual(eventsServiceBaseURL, URL(string: "https://vault.bitwarden.com/events")!)

        let identityServiceBaseURL = await subject.identityService.baseURL
        XCTAssertEqual(identityServiceBaseURL, URL(string: "https://vault.bitwarden.com/identity")!)
    }
}
