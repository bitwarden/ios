import XCTest

@testable import BitwardenShared

class AccountRevisionDateResponseModelTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(response:)` sets the date to `nil` if a date isn't able to be parsed from the response.
    func test_init_invalidDate() throws {
        let subject = try AccountRevisionDateResponseModel(response: .success(body: Data()))
        XCTAssertNil(subject.date)
    }

    /// `init(response:)` parses the date from the plain text response.
    func test_init_validDate() throws {
        let subject = try AccountRevisionDateResponseModel(
            response: .success(body: Data("1704067200000".utf8))
        )
        XCTAssertEqual(subject.date, Date(timeIntervalSince1970: 1_704_067_200))
    }
}
