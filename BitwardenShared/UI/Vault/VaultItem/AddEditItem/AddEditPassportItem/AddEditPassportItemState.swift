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

// MARK: - Display Helpers

// TODO: PM-38360 - Remove this `Display Helpers` extension (and the read-only date fields it backs)
// once the shared `DateFieldPicker` and date utilities replace them.
extension AddEditPassportItemState {
    /// The date of birth formatted as a long localized date (e.g. "August 10, 2026"); empty when unset.
    var dateOfBirthDisplay: String { Self.displayDate(from: dateOfBirth) }

    /// The expiration date formatted as a long localized date (e.g. "August 10, 2026"); empty when unset.
    var expirationDateDisplay: String { Self.displayDate(from: expirationDate) }

    /// The issue date formatted as a long localized date (e.g. "August 10, 2026"); empty when unset.
    var issueDateDisplay: String { Self.displayDate(from: issueDate) }

    /// Formats a `Date` as a long localized date (e.g. "August 10, 2026"), or returns an empty
    /// string when the value is unset.
    private static func displayDate(from date: Date?) -> String {
        guard let date else { return "" }
        return date.formatted(date: .long, time: .omitted)
    }
}
