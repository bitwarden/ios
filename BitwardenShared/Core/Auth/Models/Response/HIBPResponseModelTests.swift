import XCTest

@testable import BitwardenShared
@testable import Networking

// MARK: - HIBPResponseModelTests

class HIBPResponseModelTests: BitwardenTestCase {
    /// Tests the successful decoding of a leaked password plain text response.
    func test_decode() {
        let subject = HIBPResponseModel(response: HTTPResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            headers: [:],
            body: APITestData.hibpLeakedPasswords.data,
            requestID: UUID()
        ))

        XCTAssertEqual(
            subject.leakedHashes,
            [
                "0018A45C4D1DEF81644B54AB7F969B88D65": 1,
                "00D4F6E8FA6EECAD2A3AA415EEC418D38EC": 2,
                "011053FD0102E94D6AE2F8B83D76FAF94F6": 1,
                "012A7CA357541F0AC487871FEEC1891C49C": 2,
                "0136E006E24E7D152139815FB0FC6A50B15": 2,
                "00F63F04F8D0665B56163A132FAF935F8ED": 2,
                "32EB644B27147B66896492634584655FC2L": 1,
                "D342A499DFD4D283D872CCF598D8A7B6039": 33288,
            ]
        )
    }
}
