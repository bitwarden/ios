import Foundation

// MARK: AddEditPassportItemState

/// A protocol for a sendable type that models a passport item in its add/edit state.
///
protocol AddEditPassportItemState: Equatable, Sendable {
    /// The place of birth on the passport.
    var birthPlace: String { get set }

    /// The date of birth on the passport.
    var dateOfBirth: Date? { get set }

    /// The expiration date of the passport.
    var expirationDate: Date? { get set }

    /// The given name (first name) on the passport.
    var givenName: String { get set }

    /// Whether the national identification number is visible.
    var isNationalIdentificationNumberVisible: Bool { get set }

    /// Whether the passport number is visible.
    var isPassportNumberVisible: Bool { get set }

    /// The issue date of the passport.
    var issueDate: Date? { get set }

    /// The authority/office that issued the passport.
    var issuingAuthority: String { get set }

    /// The country that issued the passport.
    var issuingCountry: String { get set }

    /// The national identification number on the passport.
    var nationalIdentificationNumber: String { get set }

    /// The nationality on the passport.
    var nationality: String { get set }

    /// The passport number.
    var passportNumber: String { get set }

    /// The type of passport.
    var passportType: String { get set }

    /// The sex on the passport.
    var sex: String { get set }

    /// The surname (last name) on the passport.
    var surname: String { get set }
}
