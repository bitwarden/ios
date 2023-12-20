// MARK: - AddEditIdentityItemAction

import BitwardenSdk

/// Actions that can be handled by an `AddEditItemProcessor`.
enum AddEditIdentityItemAction: Equatable {
    /// The title field was changed.
    case titleChanged(DefaultableType<TitleType>)

    /// The first name field was changed.
    case firstNameChanged(String)

    /// The last name field was changed.
    case lastNameChanged(String)

    /// The middle name field was changed.
    case middleNameChanged(String)

    /// The user name field was changed.
    case userNameChanged(String)

    /// The company field was changed.
    case companyChanged(String)

    /// The SSN field was changed.
    case socialSecurityNumberChanged(String)

    /// The passport number field was changed.
    case passportNumberChanged(String)

    /// The license number field was changed.
    case licenseNumberChanged(String)

    /// The email address field was changed.
    case emailChanged(String)

    /// The phone number field was changed.
    case phoneNumberChanged(String)

    /// The address line 1 field was changed.
    case address1Changed(String)

    /// The address line 2 field was changed.
    case address2Changed(String)

    /// The address line 3 field was changed.
    case address3Changed(String)

    /// The city/town field was changed.
    case cityOrTownChanged(String)

    /// The state field was changed.
    case stateChanged(String)

    /// The postal code field was changed.
    case postalCodeChanged(String)

    /// The country field was changed.
    case countryChanged(String)
}
