/// API model for a cipher identity.
///
struct CipherIdentityModel: Codable, Equatable {
    // MARK: Properties

    /// The identity's address line 1.
    let address1: String?

    /// The identity's address line 2.
    let address2: String?

    /// The identity's address line 3.
    let address3: String?

    /// The identity's city.
    let city: String?

    /// The identity's company.
    let company: String?

    /// The identity's country.
    let country: String?

    /// The identity's email.
    let email: String?

    /// The identity's first name.
    let firstName: String?

    /// The identity's last name.
    let lastName: String?

    /// The identity's license number.
    let licenseNumber: String?

    /// The identity's middle name.
    let middleName: String?

    /// The identity's passport number.
    let passportNumber: String?

    /// The identity's phone number.
    let phone: String?

    /// The identity's postal code.
    let postalCode: String?

    /// The identity's SSN.
    let ssn: String?

    /// The identity's state.
    let state: String?

    /// The identity's title.
    let title: String?

    /// The identity's username.
    let username: String?
}
