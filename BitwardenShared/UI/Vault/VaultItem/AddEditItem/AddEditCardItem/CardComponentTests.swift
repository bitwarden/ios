// swiftlint:disable:this file_name

import XCTest

@testable import BitwardenShared

// MARK: - CardComponentBrandTests

class CardComponentBrandTests: BitwardenTestCase {
    // MARK: Tests

    /// `getter:icon` returns the appropriate icon for each card brand.
    func test_icon() {
        XCTAssertEqual(CardComponent.Brand.americanExpress.icon.name, Asset.Images.Cards.amex.name)
        XCTAssertEqual(CardComponent.Brand.visa.icon.name, Asset.Images.Cards.visa.name)
        XCTAssertEqual(CardComponent.Brand.mastercard.icon.name, Asset.Images.Cards.mastercard.name)
        XCTAssertEqual(CardComponent.Brand.discover.icon.name, Asset.Images.Cards.discover.name)
        XCTAssertEqual(CardComponent.Brand.dinersClub.icon.name, Asset.Images.Cards.dinersClub.name)
        XCTAssertEqual(CardComponent.Brand.jcb.icon.name, Asset.Images.Cards.jcb.name)
        XCTAssertEqual(CardComponent.Brand.maestro.icon.name, Asset.Images.Cards.maestro.name)
        XCTAssertEqual(CardComponent.Brand.unionPay.icon.name, Asset.Images.Cards.unionPay.name)
        XCTAssertEqual(CardComponent.Brand.ruPay.icon.name, Asset.Images.Cards.ruPay.name)
        XCTAssertEqual(CardComponent.Brand.other.icon.name, Asset.Images.card24.name)
    }
}
