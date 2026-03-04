import XCTest

@testable import BitwardenShared

class ServerVersionTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(_:)` returns `nil` on invalid format on server versions.
    func test_init_invalidFormatVersions() {
        XCTAssertNil(ServerVersion(" "))
        XCTAssertNil(ServerVersion(""))
        XCTAssertNil(ServerVersion("2024"))
        XCTAssertNil(ServerVersion("2024.2.0.1"))
        XCTAssertNil(ServerVersion("2024..2..0"))
        XCTAssertNil(ServerVersion("x.y.z-2024.2.0"))
        XCTAssertNil(ServerVersion("2024;2-0#metadata"))
    }

    /// `init(_:)` returns the struct correctly on valid format on server versions.
    func test_init_validFormatVersions() {
        XCTAssertNotNil(ServerVersion("2024.0.0"))
        XCTAssertNotNil(ServerVersion("2024.18.1"))
        XCTAssertNotNil(ServerVersion("2024.18.1"))
        XCTAssertNotNil(ServerVersion("2020.4.3-legacy"))
        XCTAssertNotNil(ServerVersion("2020.4.3-legacy-legacy"))
        XCTAssertNotNil(ServerVersion("   2024.2.0   "))
    }

    /// `<` Correctly checks if one version is less than the other version.
    func test_lesserThan() throws {
        // First component
        try XCTAssertTrue(XCTUnwrap(ServerVersion("2024.8.123")) < XCTUnwrap(ServerVersion("2025.12.300")))
        try XCTAssertTrue(XCTUnwrap(ServerVersion("2024.8.123-legacy")) < XCTUnwrap(ServerVersion("2025.12.300")))
        try XCTAssertFalse(XCTUnwrap(ServerVersion("2025.8.2")) < XCTUnwrap(ServerVersion("2024.8.1")))

        // Second component
        try XCTAssertTrue(XCTUnwrap(ServerVersion("2024.7.1234")) < XCTUnwrap(ServerVersion("2024.8.2")))
        try XCTAssertTrue(XCTUnwrap(ServerVersion("2024.7.1234-legacy")) < XCTUnwrap(ServerVersion("2024.8.2")))
        try XCTAssertFalse(XCTUnwrap(ServerVersion("2024.8.0")) < XCTUnwrap(ServerVersion("2024.7.1234")))

        // Third component
        try XCTAssertTrue(XCTUnwrap(ServerVersion("2024.8.1")) < XCTUnwrap(ServerVersion("2024.8.2")))
        try XCTAssertTrue(XCTUnwrap(ServerVersion("2024.8.1-legacy")) < XCTUnwrap(ServerVersion("2024.8.2")))
        try XCTAssertFalse(XCTUnwrap(ServerVersion("2024.8.2")) < XCTUnwrap(ServerVersion("2024.8.1")))
        // swiftlint:disable:next identical_operands
        try XCTAssertFalse(XCTUnwrap(ServerVersion("2024.8.2")) < XCTUnwrap(ServerVersion("2024.8.2")))
    }

    /// `==` Correctly checks if two versions are equal.
    func test_equals() throws {
        // swiftlint:disable:next identical_operands
        try XCTAssertTrue(XCTUnwrap(ServerVersion("2024.8.1")) == XCTUnwrap(ServerVersion("2024.8.1")))
        try XCTAssertTrue(XCTUnwrap(ServerVersion("2024.8.2")) != XCTUnwrap(ServerVersion("2024.8.1")))
        // swiftlint:disable:next identical_operands
        try XCTAssertTrue(XCTUnwrap(ServerVersion("2024.4.3-legacy")) == XCTUnwrap(ServerVersion("2024.4.3-legacy")))
        try XCTAssertFalse(XCTUnwrap(ServerVersion("2020.4.3-legacy")) == XCTUnwrap(ServerVersion("2024.4.3")))
    }
}
