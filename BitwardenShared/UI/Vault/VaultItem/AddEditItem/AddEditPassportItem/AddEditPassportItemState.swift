import Foundation

// MARK: AddEditPassportItemState

/// A protocol for a sendable type that models a passport item in its add/edit state.
///
protocol AddEditPassportItemState: Equatable, Sendable {
    /// The place of birth on the passport.
    var birthPlace: String { get set }

    /// The date of birth on the passport, held as a raw ISO string.
    var dateOfBirth: String { get set }

    /// The expiration date of the passport, held as a raw ISO string.
    var expirationDate: String { get set }

    /// The given name (first name) on the passport.
    var givenName: String { get set }

    /// Whether the national identification number is visible.
    var isNationalIdentificationNumberVisible: Bool { get set }

    /// Whether the passport number is visible.
    var isPassportNumberVisible: Bool { get set }

    /// The issue date of the passport, held as a raw ISO string.
    var issueDate: String { get set }

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

extension AddEditPassportItemState {
    /// The date of birth formatted as a long localized date (e.g. "August 10, 2026"); empty when unset.
    var dateOfBirthDisplay: String { Self.displayDate(from: dateOfBirth) }

    /// The expiration date formatted as a long localized date (e.g. "August 10, 2026"); empty when unset.
    var expirationDateDisplay: String { Self.displayDate(from: expirationDate) }

    /// The issue date formatted as a long localized date (e.g. "August 10, 2026"); empty when unset.
    var issueDateDisplay: String { Self.displayDate(from: issueDate) }

    /// Formats a raw ISO-8601 date-only string (`yyyy-MM-dd`) as a long localized date for display
    /// (e.g. "August 10, 2026"), or returns an empty string when the value is unset or unparsable.
    ///
    /// Parses fixed to UTC so a stored date reads back as the same calendar day regardless of device
    /// locale. Self-contained intentionally; PM-38360 introduces the shared `DateFieldPicker` and date
    /// utilities that will replace these read-only fields.
    private static func displayDate(from isoString: String) -> String {
        guard !isoString.isEmpty else { return "" }
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(identifier: "UTC")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: isoString) else { return "" }
        return date.formatted(date: .long, time: .omitted)
    }
}
