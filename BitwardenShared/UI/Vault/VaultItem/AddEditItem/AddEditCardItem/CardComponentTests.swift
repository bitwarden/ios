// swiftlint:disable:this file_name

import BitwardenResources
import XCTest

@testable import BitwardenShared

// MARK: - CardComponentBrandTests

class CardComponentBrandTests: BitwardenTestCase {
    // MARK: Tests

    /// `getter:icon` returns the appropriate icon for each card brand.
    func test_icon() {
        XCTAssertEqual(CardComponent.Brand.americanExpress.icon.name, SharedAsset.Icons.Cards.amex.name)
        XCTAssertEqual(CardComponent.Brand.visa.icon.name, SharedAsset.Icons.Cards.visa.name)
        XCTAssertEqual(CardComponent.Brand.mastercard.icon.name, SharedAsset.Icons.Cards.mastercard.name)
        XCTAssertEqual(CardComponent.Brand.discover.icon.name, SharedAsset.Icons.Cards.discover.name)
        XCTAssertEqual(CardComponent.Brand.dinersClub.icon.name, SharedAsset.Icons.Cards.dinersClub.name)
        XCTAssertEqual(CardComponent.Brand.jcb.icon.name, SharedAsset.Icons.Cards.jcb.name)
        XCTAssertEqual(CardComponent.Brand.maestro.icon.name, SharedAsset.Icons.Cards.maestro.name)
        XCTAssertEqual(CardComponent.Brand.unionPay.icon.name, SharedAsset.Icons.Cards.unionPay.name)
        XCTAssertEqual(CardComponent.Brand.ruPay.icon.name, SharedAsset.Icons.Cards.ruPay.name)
        XCTAssertEqual(CardComponent.Brand.other.icon.name, SharedAsset.Icons.card24.name)
    }
}
