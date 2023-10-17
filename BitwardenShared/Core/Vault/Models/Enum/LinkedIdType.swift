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
