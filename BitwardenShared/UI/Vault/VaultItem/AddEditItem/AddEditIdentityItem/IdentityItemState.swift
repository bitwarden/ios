import BitwardenSdk
import Foundation

// MARK: - IdentityItemState

/// The state for adding a Identity item.
struct IdentityItemState: Equatable {
    // MARK: Properties

    /// The title (Mr, Mrs,Ms, Mx, Dr) for this item.
    var title: DefaultableType<TitleType> = .default(TitleType.defaultStateTitle)

    /// The firstName for this item.
    var firstName: String = ""

    /// The first name for this item.
    var lastName: String = ""

    /// The middle name for this item.
    var middleName: String = ""

    /// The user name for this item.
    var userName: String = ""

    /// The company for this item.
    var company: String = ""

    /// The social security number for this item.
    var socialSecurityNumber: String = ""

    /// The passport number for this item.
    var passportNumber: String = ""

    /// The license number for this item.
    var licenseNumber: String = ""

    /// The email address for this item.
    var email: String = ""

    /// The phone number for this item.
    var phone: String = ""

    /// The address 1 for this item.
    var address1: String = ""

    /// The address line 2 for this item.
    var address2: String = ""

    /// The address line 3 for this item.
    var address3: String = ""

    /// The city/town for this item.
    var cityOrTown: String = ""

    /// The state for this item.
    var state: String = ""

    /// The postal code for this item.
    var postalCode: String = ""

    /// The country for this item.
    var country: String = ""

    var identityView: IdentityView {
        var titleStr: String?
        if case let .custom(titleType) = title {
            titleStr = titleType.rawValue
        }
        return IdentityView(
            title: titleStr,
            firstName: firstName.nilIfEmpty,
            middleName: middleName.nilIfEmpty,
            lastName: lastName.nilIfEmpty,
            address1: address1.nilIfEmpty,
            address2: address2.nilIfEmpty,
            address3: address3.nilIfEmpty,
            city: cityOrTown.nilIfEmpty,
            state: state.nilIfEmpty,
            postalCode: postalCode.nilIfEmpty,
            country: country.nilIfEmpty,
            company: company.nilIfEmpty,
            email: email.nilIfEmpty,
            phone: phone.nilIfEmpty,
            ssn: socialSecurityNumber.nilIfEmpty,
            username: userName.nilIfEmpty,
            passportNumber: passportNumber.nilIfEmpty,
            licenseNumber: licenseNumber.nilIfEmpty
        )
    }
}
