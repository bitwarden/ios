import BitwardenResources

/// An enum describing the fields that a custom cipher field can be linked to.
///
enum LinkedIdType: UInt32, Codable {
    // MARK: Login

    /// The field is linked to the login's username.
    case loginUsername = 100

    /// The field is linked to the login's password.
    case loginPassword = 101

    // MARK: Card

    /// The field is linked to the card's cardholder name.
    case cardCardholderName = 300

    /// The field is linked to the card's expiration month.
    case cardExpMonth = 301

    /// The field is linked to the card's expiration year.
    case cardExpYear = 302

    /// The field is linked to the card's code.
    case cardCode = 303

    /// The field is linked to the card's brand.
    case cardBrand = 304

    /// The field is linked to the card's number.
    case cardNumber = 305

    // MARK: Identity

    /// The field is linked to the identity's title.
    case identityTitle = 400

    /// The field is linked to the identity's middle name.
    case identityMiddleName = 401

    /// The field is linked to the identity's address line 1.
    case identityAddress1 = 402

    /// The field is linked to the identity's address line 2.
    case identityAddress2 = 403

    /// The field is linked to the identity's address line 3.
    case identityAddress3 = 404

    /// The field is linked to the identity's city.
    case identityCity = 405

    /// The field is linked to the identity's state.
    case identityState = 406

    /// The field is linked to the identity's postal code.
    case identityPostalCode = 407

    /// The field is linked to the identity's country.
    case identityCountry = 408

    /// The field is linked to the identity's company.
    case identityCompany = 409

    /// The field is linked to the identity's email.
    case identityEmail = 410

    /// The field is linked to the identity's phone.
    case identityPhone = 411

    /// The field is linked to the identity's SSN.
    case identitySsn = 412

    /// The field is linked to the identity's username.
    case identityUsername = 413

    /// The field is linked to the identity's passport number.
    case identityPassportNumber = 414

    /// The field is linked to the identity's license number.
    case identityLicenseNumber = 415

    /// The field is linked to the identity's first name.
    case identityFirstName = 416

    /// The field is linked to the identity's last name.
    case identityLastName = 417

    /// The field is linked to the identity's full name.
    case identityFullName = 418
}

extension LinkedIdType {
    /// A localized name value. This is used to describe this value in the UI.
    var localizedName: String {
        switch self {
        case .loginUsername:
            Localizations.username
        case .loginPassword:
            Localizations.password
        case .cardCardholderName:
            Localizations.cardholderName
        case .cardExpMonth:
            Localizations.expirationMonth
        case .cardExpYear:
            Localizations.expirationYear
        case .cardCode:
            Localizations.securityCode
        case .cardBrand:
            Localizations.brand
        case .cardNumber:
            Localizations.number
        case .identityTitle:
            Localizations.title
        case .identityMiddleName:
            Localizations.middleName
        case .identityAddress1:
            Localizations.address1
        case .identityAddress2:
            Localizations.address2
        case .identityAddress3:
            Localizations.address3
        case .identityCity:
            Localizations.cityTown
        case .identityState:
            Localizations.stateProvince
        case .identityPostalCode:
            Localizations.zipPostalCode
        case .identityCountry:
            Localizations.country
        case .identityCompany:
            Localizations.company
        case .identityEmail:
            Localizations.email
        case .identityPhone:
            Localizations.phone
        case .identitySsn:
            Localizations.ssn
        case .identityUsername:
            Localizations.username
        case .identityPassportNumber:
            Localizations.passportNumber
        case .identityLicenseNumber:
            Localizations.licenseNumber
        case .identityFirstName:
            Localizations.firstName
        case .identityLastName:
            Localizations.lastName
        case .identityFullName:
            Localizations.fullName
        }
    }

    /// Returns an array of LinkedIdType for a given CipherType.
    /// - Parameter cipherType: The CipherType for which the LinkedIdType values are requested.
    /// - Returns: An array of LinkedIdType values associated with the provided CipherType.
    ///
    static func getLinkedIdType(for cipherType: CipherType) -> [LinkedIdType] {
        switch cipherType {
        case .card:
            [
                .cardCardholderName,
                .cardExpMonth,
                .cardExpYear,
                .cardCode,
                .cardBrand,
                .cardNumber,
            ]
        case .identity:
            [
                .identityTitle,
                .identityMiddleName,
                .identityAddress1,
                .identityAddress2,
                .identityAddress3,
                .identityCity,
                .identityState,
                .identityPostalCode,
                .identityCountry,
                .identityCompany,
                .identityEmail,
                .identityPhone,
                .identitySsn,
                .identityUsername,
                .identityPassportNumber,
                .identityLicenseNumber,
                .identityFirstName,
                .identityLastName,
                .identityFullName,
            ]
        case .login:
            [
                .loginUsername,
                .loginPassword,
            ]
        case .secureNote:
            []
        case .sshKey:
            []
        }
    }
}

// MARK: - Identifiable

extension LinkedIdType: Identifiable {
    public var id: String {
        "\(rawValue)"
    }
}
