import XCTest

@testable import BitwardenShared

// MARK: - AgentAccessQRCodeTests

class AgentAccessQRCodeTests: BitwardenTestCase {
    /// `image(for:scale:)` renders a square image for a token.
    func test_image() throws {
        let token = String(repeating: "a", count: 64) + "_" + String(repeating: "b", count: 64)

        let image = try XCTUnwrap(AgentAccessQRCode.image(for: token))

        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertEqual(image.size.width, image.size.height)
    }

    /// `image(for:scale:)` scales the image by the number of points per module.
    func test_image_scale() throws {
        let small = try XCTUnwrap(AgentAccessQRCode.image(for: "token", scale: 1))
        let large = try XCTUnwrap(AgentAccessQRCode.image(for: "token", scale: 4))

        XCTAssertEqual(large.size.width, small.size.width * 4)
    }
}
