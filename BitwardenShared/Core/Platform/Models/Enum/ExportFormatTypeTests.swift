import XCTest

@testable import BitwardenShared

class ExportFormatTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `localizedName` returns the correct values.
    func test_localizedName() {
        XCTAssertEqual(ExportFormatType.csv.localizedName, ".csv")
        XCTAssertEqual(ExportFormatType.json.localizedName, ".json")
        XCTAssertEqual(ExportFormatType.jsonEncrypted.localizedName, ".json (Password protected)")
    }
}
