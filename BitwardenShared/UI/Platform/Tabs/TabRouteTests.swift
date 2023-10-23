import UIKit
import XCTest

@testable import BitwardenShared

// MARK: - TabRouteTests

class TabRouteTests: BitwardenTestCase {
    // MARK: Tests

    /// `.generator` image is the `.restart` asset.
    func test_generator_image() {
        XCTAssertEqual(TabRoute.generator(.generator).image?.pngData(), Asset.Images.restart.image.pngData())
    }

    /// `.generator` is the third tab.
    func test_generator_rawValue() {
        XCTAssertEqual(TabRoute.generator(.generator).index, 2)
    }

    /// `.generator` selected image is the `.restartFilled` asset.
    func test_generator_selectedImage() {
        XCTAssertEqual(
            TabRoute.generator(.generator).selectedImage?.pngData(),
            Asset.Images.restartFilled.image.pngData()
        )
    }

    /// `.generator` uses the correct localized title.
    func test_generator_title() {
        XCTAssertEqual(TabRoute.generator(.generator).title, Localizations.generator)
    }

    /// `.send` image is the `.send` asset.
    func test_send_image() {
        XCTAssertEqual(TabRoute.send.image?.pngData(), Asset.Images.send.image.pngData())
    }

    /// `.send` is the second tab.
    func test_send_rawValue() {
        XCTAssertEqual(TabRoute.send.index, 1)
    }

    /// `.send` selected image is the `.sendFilled` asset.
    func test_send_selectedImage() {
        XCTAssertEqual(TabRoute.send.selectedImage?.pngData(), Asset.Images.sendFilled.image.pngData())
    }

    /// `.send` uses the correct localized title.
    func test_send_title() {
        XCTAssertEqual(TabRoute.send.title, Localizations.send)
    }

    /// `.settings` image is the `.gear` asset.
    func test_settings_image() {
        XCTAssertEqual(TabRoute.settings.image?.pngData(), Asset.Images.gear.image.pngData())
    }

    /// `.settings` is the fourth tab.
    func test_settings_rawValue() {
        XCTAssertEqual(TabRoute.settings.index, 3)
    }

    /// `.settings` selected image is the `.gearFilled` asset.
    func test_settings_selectedImage() {
        XCTAssertEqual(TabRoute.settings.selectedImage?.pngData(), Asset.Images.gearFilled.image.pngData())
    }

    /// `.settings` uses the correct localized title.
    func test_settings_title() {
        XCTAssertEqual(TabRoute.settings.title, Localizations.settings)
    }

    /// `.vault` image is the `.locked` asset.
    func test_vault_image() {
        XCTAssertEqual(TabRoute.vault(.list).image?.pngData(), Asset.Images.locked.image.pngData())
    }

    /// `.vault` is the first tab.
    func test_vault_rawValue() {
        XCTAssertEqual(TabRoute.vault(.list).index, 0)
    }

    /// `.vault` selected image is the `.lockedFilled` asset.
    func test_vault_selectedImage() {
        XCTAssertEqual(TabRoute.vault(.list).selectedImage?.pngData(), Asset.Images.lockedFilled.image.pngData())
    }

    /// `.vault` uses the correct localized title.
    func test_vault_title() {
        XCTAssertEqual(TabRoute.vault(.list).title, Localizations.myVault)
    }
}
