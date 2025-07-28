// MARK: - CardComponent

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
    var icon: ImageAsset {
        switch self {
        case .americanExpress:
            Asset.Images.Cards.amex
        case .visa:
            Asset.Images.Cards.visa
        case .mastercard:
            Asset.Images.Cards.mastercard
        case .discover:
            Asset.Images.Cards.discover
        case .dinersClub:
            Asset.Images.Cards.dinersClub
        case .jcb:
            Asset.Images.Cards.jcb
        case .maestro:
            Asset.Images.Cards.maestro
        case .unionPay:
            Asset.Images.Cards.unionPay
        case .ruPay:
            Asset.Images.Cards.ruPay
        case .other:
            Asset.Images.card24
        }
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
