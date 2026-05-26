/// API model for a driver's license cipher.
///
struct CipherDriversLicenseModel: Codable, Equatable, Sendable {
    // MARK: Properties

    /// The date of birth.
    let dateOfBirth: String?

    /// The expiration date.
    let expirationDate: String?

    /// The first name.
    let firstName: String?

    /// The issue date.
    let issueDate: String?

    /// The issuing authority.
    let issuingAuthority: String?

    /// The issuing country.
    let issuingCountry: String?

    /// The issuing state.
    let issuingState: String?

    /// The last name.
    let lastName: String?

    /// The license class.
    let licenseClass: String?

    /// The license number.
    let licenseNumber: String?

    /// The middle name.
    let middleName: String?
}
