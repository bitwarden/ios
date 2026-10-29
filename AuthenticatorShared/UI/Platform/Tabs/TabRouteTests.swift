import BitwardenResources
import Testing
import UIKit

@testable import AuthenticatorShared

// MARK: - TabRouteTests

struct TabRouteTests {
    // MARK: Tests

    /// `.itemList` image is the `codesIdle` asset.
    @Test
    func itemList_image() {
        #expect(
            TabRoute.itemList(.list).image?.pngData()
                == SharedAsset.Icons.TabBar.codesIdle.image.pngData(),
        )
    }

    /// `.itemList` selected image is the `codesActive` asset.
    @Test
    func itemList_selectedImage() {
        #expect(
            TabRoute.itemList(.list).selectedImage?.pngData()
                == SharedAsset.Icons.TabBar.codesActive.image.pngData(),
        )
    }

    /// `.settings` image is the `settingsIdle` asset.
    @Test
    func settings_image() {
        #expect(
            TabRoute.settings(.settings).image?.pngData()
                == SharedAsset.Icons.TabBar.settingsIdle.image.pngData(),
        )
    }

    /// `.settings` selected image is the `settingsActive` asset.
    @Test
    func settings_selectedImage() {
        #expect(
            TabRoute.settings(.settings).selectedImage?.pngData()
                == SharedAsset.Icons.TabBar.settingsActive.image.pngData(),
        )
    }
}
