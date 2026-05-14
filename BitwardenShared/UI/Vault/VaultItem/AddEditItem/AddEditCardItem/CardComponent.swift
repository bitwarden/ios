// MARK: - CardComponent

import BitwardenKit
import BitwardenResources
import Foundation

/// An enumeration defining various components associated with credit and debit cards.
///
enum CardComponent {
    /// Represents months of the year, commonly used in card expiration dates.
    ///
    enum Month: Int {
        /// 01 - January
        case jan = 1

        /// 02 - February
        case feb

        /// 03 - March
        case mar

        /// 04 - April
        case apr

        /// 05 - May
        case may

        /// 06 - June
        case jun

        /// 07 - July
        case jul

        /// 08 - August
        case aug

        /// 09 - September
        case sep

        /// 10 - October
        case oct

        /// 11- November
        case nov

        /// 12 - December
        case dec

        /// A formatted number string for the month.
        var formattedValue: String {
            let formatter = NumberFormatter()
            formatter.minimumIntegerDigits = 2
            return formatter.string(from: NSNumber(value: rawValue)) ?? "00"
        }

        /// A localized string for the month name.
        var localized: String {
            switch self {
            case .jan:
                Localizations.january
            case .feb:
                Localizations.february
            case .mar:
                Localizations.march
            case .apr:
                Localizations.april
            case .may:
                Localizations.may
            case .jun:
                Localizations.june
            case .jul:
                Localizations.july
            case .aug:
                Localizations.august
            case .sep:
                Localizations.september
            case .oct:
                Localizations.october
            case .nov:
                Localizations.november
            case .dec:
                Localizations.december
            }
        }
    }

    /// Represents various credit card brands.
    ///
    enum Brand: String {
        /// Visa
        case visa = "Visa"

        /// Mastercard
        case mastercard = "Mastercard" // swiftlint:disable:this inclusive_language

        /// American Express
        case americanExpress = "Amex"

        /// Discover
        case discover = "Discover"

        /// Diners Club
        case dinersClub = "Diners Club"

        /// JCB
        case jcb = "JCB"

        /// Maestro
        case maestro = "Maestro"

        /// UnionPay
        case unionPay = "UnionPay"

        /// RuPay
        case ruPay = "RuPay"

        /// Other brands not explicitly listed here
        case other = "Other"
    }
}

extension CardComponent.Brand {
    /// Infers the card brand from the leading digits of a card number.
    ///
    /// - Parameter number: The card number (digits only, no spaces).
    /// - Returns: The detected brand, or `.other` if unrecognized.
    static func detect(from number: String) -> CardComponent.Brand { // swiftlint:disable:this cyclomatic_complexity
        guard !number.isEmpty else { return .other }

        if number.hasPrefix("4") { return .visa }

        if number.hasPrefix("34") || number.hasPrefix("37") { return .americanExpress }

        if let prefix2 = Int(number.prefix(2)) {
            if (51 ... 55).contains(prefix2) { return .mastercard }
            if prefix2 == 36 || prefix2 == 38 { return .dinersClub }
            if prefix2 == 35 { return .jcb }
        }

        if let prefix4 = Int(number.prefix(4)) {
            if prefix4 == 6011 { return .discover }
            if [5018, 5020, 5038, 6304, 6759].contains(prefix4) { return .maestro }
            if (3528 ... 3589).contains(prefix4) { return .jcb }
            if (2221 ... 2720).contains(prefix4) { return .mastercard }
            if (3000 ... 3059).contains(prefix4) { return .dinersClub }
        }

        if let prefix6 = Int(number.prefix(6)) {
            if (622_126 ... 622_925).contains(prefix6) { return .discover }
        }

        if let prefix2 = Int(number.prefix(2)) {
            if prefix2 == 62 { return .unionPay }
            if prefix2 == 60 { return .ruPay }
            if (64 ... 65).contains(prefix2) { return .discover }
            if (56 ... 58).contains(prefix2) { return .maestro }
        }

        return .other
    }
}

extension CardComponent.Brand: CaseIterable {}
extension CardComponent.Brand: Menuable {
    /// default state title for title type
    static var defaultValueLocalizedName: String {
        "--\(Localizations.select)--"
    }

    /// Provides a localized string representation of the card brand.
    /// For the 'other' case, it returns a localized string for 'Other'.
    var localizedName: String {
        guard case .other = self else {
            if case .americanExpress = self {
                return "American Express"
            }
            return rawValue
        }
        return Localizations.other
    }
}

extension CardComponent.Brand {
    /// Gets the icon corresponding to each card brand.
    var icon: SharedImageAsset {
        switch self {
        case .americanExpress:
            SharedAsset.Icons.Cards.amex
        case .visa:
            SharedAsset.Icons.Cards.visa
        case .mastercard:
            SharedAsset.Icons.Cards.mastercard
        case .discover:
            SharedAsset.Icons.Cards.discover
        case .dinersClub:
            SharedAsset.Icons.Cards.dinersClub
        case .jcb:
            SharedAsset.Icons.Cards.jcb
        case .maestro:
            SharedAsset.Icons.Cards.maestro
        case .unionPay:
            SharedAsset.Icons.Cards.unionPay
        case .ruPay:
            SharedAsset.Icons.Cards.ruPay
        case .other:
            SharedAsset.Icons.card24
        }
    }
}

extension CardComponent.Brand {
    /// Returns the digit-group block sizes to use when formatting this brand for display.
    ///
    /// - Parameter digitCount: The number of digits in the card number being formatted.
    ///   Used for length-sensitive brands (Maestro, UnionPay).
    /// - Returns: An array of block widths, where each element is the number of digits in one
    ///   space-separated group.
    ///
    func formattingBlocks(for digitCount: Int) -> [Int] {
        switch self {
        case .americanExpress:
            [4, 6, 5]
        case .dinersClub:
            [4, 6, 4]
        case .maestro:
            switch digitCount {
            case 13: [4, 4, 5]
            case 15: [4, 6, 5]
            case 19: [4, 4, 4, 4, 3]
            default: [4, 4, 4, 4]
            }
        case .unionPay:
            digitCount == 19 ? [6, 13] : [4, 4, 4, 4]
        default:
            [4, 4, 4, 4]
        }
    }

    /// Formats a card number string with brand-appropriate digit grouping.
    ///
    /// Partial numbers (e.g. while the user is typing) are handled greedily: blocks are filled
    /// left-to-right until the digits run out. Any digits beyond the defined blocks are appended
    /// as a trailing group to prevent silent data loss.
    ///
    /// Returns the input unchanged if it contains non-digit characters.
    ///
    /// - Parameter number: The raw card number containing only digit characters.
    /// - Returns: A display string with spaces between digit groups.
    ///
    func formattedCardNumber(_ number: String) -> String {
        guard !number.isEmpty, number.allSatisfy(\.isNumber) else { return number }
        let digits = Array(number)
        let blocks = formattingBlocks(for: digits.count)
        var result = ""
        var position = 0
        for (iPos, size) in blocks.enumerated() {
            guard position < digits.count else { break }
            if iPos > 0 { result += " " }
            let end = min(position + size, digits.count)
            result += String(digits[position ..< end])
            position = end
        }
        if position < digits.count {
            result += " " + String(digits[position...])
        }
        return result
    }
}

extension CardComponent.Month: CaseIterable {}
extension CardComponent.Month: Menuable {
    /// default state title for title type
    static var defaultValueLocalizedName: String {
        "--\(Localizations.select)--"
    }

    var localizedName: String {
        "\(formattedValue) - \(localized)"
    }
}
