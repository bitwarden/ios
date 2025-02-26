import XCTest

@testable import BitwardenShared

// MARK: - KnownDeviceResponseModelTests

class KnownDeviceResponseModelTests: BitwardenTestCase {
    // MARK: Init

    /// `init(isKnownDevice:)` sets the corresponding values.
    func test_init() {
        let subject = KnownDeviceResponseModel(isKnownDevice: true)
        XCTAssertTrue(subject.isKnownDevice)
    }

    // MARK: Decoding

    /// Validates decoding the `KnownDeviceFalse.json` fixture.
    func test_decode_False() throws {
        let json = APITestData.knownDeviceFalse.data
        let decoder = JSONDecoder()
        let subject = try decoder.decode(KnownDeviceResponseModel.self, from: json)
        XCTAssertFalse(subject.isKnownDevice)
    }

    /// Validates decoding the `KnownDeviceTrue.json` fixture.
    func test_decode_True() throws {
        let json = APITestData.knownDeviceTrue.data
        let decoder = JSONDecoder()
        let subject = try decoder.decode(KnownDeviceResponseModel.self, from: json)
        XCTAssertTrue(subject.isKnownDevice)
    }
}
