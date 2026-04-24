/// API model for a driver's license cipher.
///
struct CipherDriversLicenseModel: Codable, Equatable, Sendable {
    // MARK: Properties

    /// The license expiration day.
    let expirationDay: String?

    /// The license expiration month.
    let expirationMonth: String?

    /// The license expiration year.
    let expirationYear: String?

    /// The first name on the license.
    let firstName: String?

    /// The issuing country.
    let issuingCountry: String?

    /// The issuing state or province.
    let issuingState: String?

    /// The last name on the license.
    let lastName: String?

    /// The class of the license.
    let licenseClass: String?

    /// The license number.
    let licenseNumber: String?

    /// The middle name on the license.
    let middleName: String?
}
