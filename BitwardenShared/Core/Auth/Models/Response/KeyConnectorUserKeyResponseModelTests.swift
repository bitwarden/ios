import XCTest

@testable import BitwardenShared

class KeyConnectorUserKeyResponseModelTests: BitwardenTestCase {
    // MARK: - Tests

    /// Tests the successful decoding of a JSON response.
    func test_decode_success() throws {
        let json = APITestData.keyConnectorUserKey.data
        let subject = try KeyConnectorUserKeyResponseModel.decoder.decode(
            KeyConnectorUserKeyResponseModel.self,
            from: json
        )
        XCTAssertEqual(subject.key, "EXsYYd2Wx4H/9dhzmINS0P30lpG8bZ44RRn/T15tVA8=")
    }
}
