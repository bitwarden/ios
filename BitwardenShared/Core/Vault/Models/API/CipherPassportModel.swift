/// API model for a passport cipher.
///
struct CipherPassportModel: Codable, Equatable, Sendable {
    // MARK: Properties

    /// The place of birth.
    let birthPlace: String?

    /// The date of birth.
    let dateOfBirth: String?

    /// The expiration date.
    let expirationDate: String?

    /// The given name.
    let givenName: String?

    /// The issue date.
    let issueDate: String?

    /// The issuing authority.
    let issuingAuthority: String?

    /// The issuing country.
    let issuingCountry: String?

    /// The national identification number.
    let nationalIdentificationNumber: String?

    /// The nationality.
    let nationality: String?

    /// The passport number.
    let passportNumber: String?

    /// The passport type.
    let passportType: String?

    /// The sex.
    let sex: String?

    /// The surname.
    let surname: String?
}
