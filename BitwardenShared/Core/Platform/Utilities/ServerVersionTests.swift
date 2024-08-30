import XCTest

@testable import BitwardenShared

class ServerVersionTests: BitwardenTestCase {
    func test_invalidFormatVersions() {
        let version1 = ServerVersion(version: "2024.2.0")
        let version2 = ServerVersion(version: " ")
        let version3 = ServerVersion(version: "")
        let version4 = ServerVersion(version: "2024")
        let version5 = ServerVersion(version: "2024.2.0.1")
        let version6 = ServerVersion(version: "1.2.2024")
        let version7 = ServerVersion(version: "2024..2..0")
        let version8 = ServerVersion(version: "x.y.z-2024.2.0")
        let version9 = ServerVersion(version: "2024;2-0#metadata")

        XCTAssertFalse(version1 > version2)
        XCTAssertFalse(version1 < version3)
        XCTAssertFalse(version1 < version4)
        XCTAssertFalse(version1 <= version5)
        XCTAssertFalse(version1 == version6)
        XCTAssertFalse(version1 > version7)
        XCTAssertFalse(version1 <= version8)
        XCTAssertFalse(version1 <= version9)
    }

    func test_validFormatVersions() {
        let version1 = ServerVersion(version: "2020.4.3-legacy")
        let version2 = ServerVersion(version: "2024.2.0")
        let version3 = ServerVersion(version: "2024.18.1")
        let version4 = ServerVersion(version: "2024.18.1")
        let version5 = ServerVersion(version: "2020.4.3-legacy-legacy")

        XCTAssertTrue(version1 < version2)
        XCTAssertTrue(version2 < version3)
        XCTAssertTrue(version3 > version1)
        XCTAssertTrue(version3 == version4)
        XCTAssertTrue(version3 >= version4)
        XCTAssertTrue(version5 <= version2)
    }
}
