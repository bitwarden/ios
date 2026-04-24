/// API model for a passport cipher.
///
struct CipherPassportModel: Codable, Equatable, Sendable {
    // MARK: Properties

    /// The date of birth day.
    let dobDay: String?

    /// The date of birth month.
    let dobMonth: String?

    /// The date of birth year.
    let dobYear: String?

    /// The passport expiration day.
    let expirationDay: String?

    /// The passport expiration month.
    let expirationMonth: String?

    /// The passport expiration year.
    let expirationYear: String?

    /// The given name on the passport.
    let givenName: String?

    /// The passport issue day.
    let issueDay: String?

    /// The passport issue month.
    let issueMonth: String?

    /// The passport issue year.
    let issueYear: String?

    /// The issuing authority or office.
    let issuingAuthority: String?

    /// The issuing country.
    let issuingCountry: String?

    /// The nationality listed on the passport.
    let nationality: String?

    /// The passport number.
    let passportNumber: String?

    /// The passport type.
    let passportType: String?

    /// The surname on the passport.
    let surname: String?
}
