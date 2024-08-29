import XCTest

@testable import BitwardenShared

class ServerVersionTests: BitwardenTestCase {

    func test_versionComparison() {
        let version1 = ServerVersion(version: "2024.18.3")
        let version2 = ServerVersion(version: "2024.18.4")
        let version3 = ServerVersion(version: "2024.19.1")
        let version4 = ServerVersion(version: "2024.18.3")

        XCTAssertTrue(version1 < version2, "Expected \(version1.version) to be less than \(version2.version)")
        XCTAssertTrue(version2 < version3, "Expected \(version2.version) to be less than \(version3.version)")
        XCTAssertTrue(version1 == version4, "Expected \(version1.version) to be equal to \(version4.version)")
        XCTAssertTrue(version3 > version1, "Expected \(version3.version) to be greater than \(version1.version)")
    }
}
