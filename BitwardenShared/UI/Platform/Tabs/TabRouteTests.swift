import UIKit
import XCTest

@testable import BitwardenShared

// MARK: - TabRouteTests

class TabRouteTests: BitwardenTestCase {
    // MARK: Tests

    func test_generator_image() {
        XCTAssertEqual(
            TabRoute.generator.image?.pngData(),
            UIImage(systemName: "arrow.triangle.2.circlepath")?.pngData()
        )
    }

    func test_generator_rawValue() {
        XCTAssertEqual(TabRoute.generator.rawValue, 2)
    }

    func test_generator_selectedImage() {
        XCTAssertEqual(
            TabRoute.generator.selectedImage?.pngData(),
            UIImage(systemName: "arrow.triangle.2.circlepath.circle.fill")?.pngData()
        )
    }

    func test_generator_title() {
        XCTAssertEqual(TabRoute.generator.title, "Generator")
    }

    func test_send_image() {
        XCTAssertEqual(TabRoute.send.image?.pngData(), UIImage(systemName: "paperplane")?.pngData())
    }

    func test_send_rawValue() {
        XCTAssertEqual(TabRoute.send.rawValue, 1)
    }

    func test_send_selectedImage() {
        XCTAssertEqual(TabRoute.send.selectedImage?.pngData(), UIImage(systemName: "paperplane.fill")?.pngData())
    }

    func test_send_title() {
        XCTAssertEqual(TabRoute.send.title, "Send")
    }

    func test_settings_image() {
        XCTAssertEqual(TabRoute.settings.image?.pngData(), UIImage(systemName: "gearshape")?.pngData())
    }

    func test_settings_rawValue() {
        XCTAssertEqual(TabRoute.settings.rawValue, 3)
    }

    func test_settings_selectedImage() {
        XCTAssertEqual(TabRoute.settings.selectedImage?.pngData(), UIImage(systemName: "gearshape.fill")?.pngData())
    }

    func test_settings_title() {
        XCTAssertEqual(TabRoute.settings.title, "Settings")
    }

    func test_vault_image() {
        XCTAssertEqual(TabRoute.vault.image?.pngData(), UIImage(systemName: "lock")?.pngData())
    }

    func test_vault_rawValue() {
        XCTAssertEqual(TabRoute.vault.rawValue, 0)
    }

    func test_vault_selectedImage() {
        XCTAssertEqual(TabRoute.vault.selectedImage?.pngData(), UIImage(systemName: "lock.fill")?.pngData())
    }

    func test_vault_title() {
        XCTAssertEqual(TabRoute.vault.title, "My Vault")
    }
}
