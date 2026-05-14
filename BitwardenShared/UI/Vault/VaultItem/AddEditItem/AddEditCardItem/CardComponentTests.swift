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

    // MARK: Tests – detect(from:)

    /// `detect(from:)` returns `.visa` for numbers starting with 4.
    func test_detect_visa() {
        XCTAssertEqual(CardComponent.Brand.detect(from: "4111111111111111"), .visa)
        XCTAssertEqual(CardComponent.Brand.detect(from: "4"), .visa)
    }

    /// `detect(from:)` returns `.americanExpress` for numbers starting with 34 or 37.
    func test_detect_americanExpress() {
        XCTAssertEqual(CardComponent.Brand.detect(from: "378282246310005"), .americanExpress)
        XCTAssertEqual(CardComponent.Brand.detect(from: "371449635398431"), .americanExpress)
        XCTAssertEqual(CardComponent.Brand.detect(from: "341111111111111"), .americanExpress)
    }

    /// `detect(from:)` returns `.mastercard` for numbers starting with 51–55.
    func test_detect_mastercard_prefix51to55() { // swiftlint:disable:this inclusive_language
        XCTAssertEqual(CardComponent.Brand.detect(from: "5100000000000000"), .mastercard)
        XCTAssertEqual(CardComponent.Brand.detect(from: "5555555555554444"), .mastercard)
    }

    /// `detect(from:)` returns `.mastercard` for numbers in the 2221–2720 range.
    func test_detect_mastercard_prefix2221to2720() { // swiftlint:disable:this inclusive_language
        XCTAssertEqual(CardComponent.Brand.detect(from: "2221000000000000"), .mastercard)
        XCTAssertEqual(CardComponent.Brand.detect(from: "2720000000000000"), .mastercard)
    }

    /// `detect(from:)` returns `.discover` for numbers starting with 6011.
    func test_detect_discover_prefix6011() {
        XCTAssertEqual(CardComponent.Brand.detect(from: "6011111111111117"), .discover)
    }

    /// `detect(from:)` returns `.discover` for numbers in the 622126–622925 range.
    func test_detect_discover_prefix622126to622925() {
        XCTAssertEqual(CardComponent.Brand.detect(from: "6221260000000000"), .discover)
        XCTAssertEqual(CardComponent.Brand.detect(from: "6229250000000000"), .discover)
    }

    /// `detect(from:)` returns `.discover` for numbers starting with 64 or 65.
    func test_detect_discover_prefix64to65() {
        XCTAssertEqual(CardComponent.Brand.detect(from: "6400000000000000"), .discover)
        XCTAssertEqual(CardComponent.Brand.detect(from: "6500000000000000"), .discover)
    }

    /// `detect(from:)` returns `.dinersClub` for numbers starting with 36 or 38.
    func test_detect_dinersClub_prefix36_38() {
        XCTAssertEqual(CardComponent.Brand.detect(from: "36000000000000"), .dinersClub)
        XCTAssertEqual(CardComponent.Brand.detect(from: "38000000000000"), .dinersClub)
    }

    /// `detect(from:)` returns `.dinersClub` for numbers in the 3000–3059 range.
    func test_detect_dinersClub_prefix3000to3059() {
        XCTAssertEqual(CardComponent.Brand.detect(from: "3000000000000000"), .dinersClub)
        XCTAssertEqual(CardComponent.Brand.detect(from: "3059000000000000"), .dinersClub)
    }

    /// `detect(from:)` returns `.jcb` for numbers starting with 35.
    func test_detect_jcb_prefix35() {
        XCTAssertEqual(CardComponent.Brand.detect(from: "3530111333300000"), .jcb)
    }

    /// `detect(from:)` returns `.jcb` for numbers in the 3528–3589 range.
    func test_detect_jcb_prefix3528to3589() {
        XCTAssertEqual(CardComponent.Brand.detect(from: "3528000000000000"), .jcb)
        XCTAssertEqual(CardComponent.Brand.detect(from: "3589000000000000"), .jcb)
    }

    /// `detect(from:)` returns `.maestro` for the specific 4-digit prefixes 5018, 5020, 5038, 6304, 6759.
    func test_detect_maestro_specificPrefixes() {
        XCTAssertEqual(CardComponent.Brand.detect(from: "5018000000000000"), .maestro)
        XCTAssertEqual(CardComponent.Brand.detect(from: "5020000000000000"), .maestro)
        XCTAssertEqual(CardComponent.Brand.detect(from: "5038000000000000"), .maestro)
        XCTAssertEqual(CardComponent.Brand.detect(from: "6304000000000000"), .maestro)
        XCTAssertEqual(CardComponent.Brand.detect(from: "6759000000000000"), .maestro)
    }

    /// `detect(from:)` returns `.maestro` for numbers starting with 56–58.
    func test_detect_maestro_prefix56to58() {
        XCTAssertEqual(CardComponent.Brand.detect(from: "5600000000000000"), .maestro)
        XCTAssertEqual(CardComponent.Brand.detect(from: "5800000000000000"), .maestro)
    }

    /// `detect(from:)` returns `.unionPay` for numbers starting with 62.
    func test_detect_unionPay() {
        XCTAssertEqual(CardComponent.Brand.detect(from: "6200000000000000"), .unionPay)
    }

    /// `detect(from:)` returns `.ruPay` for numbers starting with 60.
    func test_detect_ruPay() {
        XCTAssertEqual(CardComponent.Brand.detect(from: "6000000000000000"), .ruPay)
    }

    /// `detect(from:)` returns `.other` for an unrecognized prefix.
    func test_detect_other_unrecognized() {
        XCTAssertEqual(CardComponent.Brand.detect(from: "9999999999999999"), .other)
    }

    /// `detect(from:)` returns `.other` for an empty string.
    func test_detect_other_emptyString() {
        XCTAssertEqual(CardComponent.Brand.detect(from: ""), .other)
    }

    // MARK: Tests – formattingBlocks(for:)

    /// `formattingBlocks(for:)` returns `[4, 6, 5]` for American Express.
    func test_formattingBlocks_americanExpress() {
        XCTAssertEqual(CardComponent.Brand.americanExpress.formattingBlocks(for: 15), [4, 6, 5])
    }

    /// `formattingBlocks(for:)` returns `[4, 6, 4]` for Diners Club.
    func test_formattingBlocks_dinersClub() {
        XCTAssertEqual(CardComponent.Brand.dinersClub.formattingBlocks(for: 14), [4, 6, 4])
    }

    /// `formattingBlocks(for:)` returns the correct blocks for each Maestro card length.
    func test_formattingBlocks_maestro() {
        XCTAssertEqual(CardComponent.Brand.maestro.formattingBlocks(for: 13), [4, 4, 5])
        XCTAssertEqual(CardComponent.Brand.maestro.formattingBlocks(for: 15), [4, 6, 5])
        XCTAssertEqual(CardComponent.Brand.maestro.formattingBlocks(for: 16), [4, 4, 4, 4])
        XCTAssertEqual(CardComponent.Brand.maestro.formattingBlocks(for: 19), [4, 4, 4, 4, 3])
    }

    /// `formattingBlocks(for:)` returns the correct blocks for each UnionPay card length.
    func test_formattingBlocks_unionPay() {
        XCTAssertEqual(CardComponent.Brand.unionPay.formattingBlocks(for: 16), [4, 4, 4, 4])
        XCTAssertEqual(CardComponent.Brand.unionPay.formattingBlocks(for: 19), [6, 13])
    }

    /// `formattingBlocks(for:)` returns `[4, 4, 4, 4]` for all standard 16-digit brands.
    func test_formattingBlocks_standard16DigitBrands() {
        for brand: CardComponent.Brand in [.visa, .mastercard, .discover, .jcb, .ruPay, .other] {
            XCTAssertEqual(brand.formattingBlocks(for: 16), [4, 4, 4, 4], "Expected [4,4,4,4] for \(brand)")
        }
    }

    // MARK: Tests – formattedCardNumber(_:)

    /// `formattedCardNumber(_:)` formats a full Visa number with 4-4-4-4 grouping.
    func test_formattedCardNumber_visa_full() {
        XCTAssertEqual(CardComponent.Brand.visa.formattedCardNumber("4111111111111111"), "4111 1111 1111 1111")
    }

    /// `formattedCardNumber(_:)` formats a partial Visa number greedily.
    func test_formattedCardNumber_visa_partial() {
        XCTAssertEqual(CardComponent.Brand.visa.formattedCardNumber("411111"), "4111 11")
        XCTAssertEqual(CardComponent.Brand.visa.formattedCardNumber("4"), "4")
        XCTAssertEqual(CardComponent.Brand.visa.formattedCardNumber(""), "")
    }

    /// `formattedCardNumber(_:)` formats a full Amex number with 4-6-5 grouping.
    func test_formattedCardNumber_amex_full() {
        XCTAssertEqual(CardComponent.Brand.americanExpress.formattedCardNumber("378282246310005"), "3782 822463 10005")
    }

    /// `formattedCardNumber(_:)` formats a partial Amex number greedily.
    func test_formattedCardNumber_amex_partial() {
        XCTAssertEqual(CardComponent.Brand.americanExpress.formattedCardNumber("37828"), "3782 8")
        XCTAssertEqual(CardComponent.Brand.americanExpress.formattedCardNumber("3782822"), "3782 822")
    }

    /// `formattedCardNumber(_:)` formats a full Diners Club number with 4-6-4 grouping.
    func test_formattedCardNumber_dinersClub_full() {
        XCTAssertEqual(CardComponent.Brand.dinersClub.formattedCardNumber("36000000000000"), "3600 000000 0000")
    }

    /// `formattedCardNumber(_:)` formats a Maestro 13-digit number with 4-4-5 grouping.
    func test_formattedCardNumber_maestro_13digits() {
        XCTAssertEqual(CardComponent.Brand.maestro.formattedCardNumber("6304000000000"), "6304 0000 00000")
    }

    /// `formattedCardNumber(_:)` formats a Maestro 15-digit number with 4-6-5 grouping.
    func test_formattedCardNumber_maestro_15digits() {
        XCTAssertEqual(CardComponent.Brand.maestro.formattedCardNumber("630400000000000"), "6304 000000 00000")
    }

    /// `formattedCardNumber(_:)` formats a Maestro 16-digit number with 4-4-4-4 grouping.
    func test_formattedCardNumber_maestro_16digits() {
        XCTAssertEqual(CardComponent.Brand.maestro.formattedCardNumber("6304000000000000"), "6304 0000 0000 0000")
    }

    /// `formattedCardNumber(_:)` formats a Maestro 19-digit number with 4-4-4-4-3 grouping.
    func test_formattedCardNumber_maestro_19digits() {
        XCTAssertEqual(
            CardComponent.Brand.maestro.formattedCardNumber("6304000000000000000"),
            "6304 0000 0000 0000 000",
        )
    }

    /// `formattedCardNumber(_:)` formats a UnionPay 16-digit number with 4-4-4-4 grouping.
    func test_formattedCardNumber_unionPay_16digits() {
        XCTAssertEqual(CardComponent.Brand.unionPay.formattedCardNumber("6200000000000000"), "6200 0000 0000 0000")
    }

    /// `formattedCardNumber(_:)` formats a UnionPay 19-digit number with 6-13 grouping.
    func test_formattedCardNumber_unionPay_19digits() {
        XCTAssertEqual(CardComponent.Brand.unionPay.formattedCardNumber("6200000000000000000"), "620000 0000000000000")
    }

    /// `formattedCardNumber(_:)` returns the input unchanged when it contains non-digit characters.
    func test_formattedCardNumber_nonDigitInput_returnsUnchanged() {
        XCTAssertEqual(CardComponent.Brand.visa.formattedCardNumber("4111-1111-1111-1111"), "4111-1111-1111-1111")
        XCTAssertEqual(CardComponent.Brand.visa.formattedCardNumber("abcd"), "abcd")
    }
}
