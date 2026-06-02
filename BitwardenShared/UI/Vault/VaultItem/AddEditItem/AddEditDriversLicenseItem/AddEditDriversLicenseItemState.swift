import Foundation

// MARK: AddEditDriversLicenseItemState

/// A protocol for a sendable type that models a Driver's License Item in it's add/edit state.
///
protocol AddEditDriversLicenseItemState: Equatable, Sendable {
    /// The date of birth on the license, held as a raw ISO string.
    var dateOfBirth: String { get set }

    /// The expiration date of the license, held as a raw ISO string.
    var expirationDate: String { get set }

    /// The first name on the license.
    var firstName: String { get set }

    /// Whether the license number is visible.
    var isLicenseNumberVisible: Bool { get set }

    /// The issue date of the license, held as a raw ISO string.
    var issueDate: String { get set }

    /// The authority that issued the license.
    var issuingAuthority: String { get set }

    /// The country that issued the license.
    var issuingCountry: String { get set }

    /// The state or province that issued the license.
    var issuingState: String { get set }

    /// The last name on the license.
    var lastName: String { get set }

    /// The class of the license.
    var licenseClass: String { get set }

    /// The number of the license.
    var licenseNumber: String { get set }

    /// The middle name on the license.
    var middleName: String { get set }
}

// MARK: - Display Helpers

extension AddEditDriversLicenseItemState {
    /// The date of birth formatted as a long localized date (e.g. "August 10, 2026"); empty when unset.
    var dateOfBirthDisplay: String { displayDate(from: dateOfBirth) }

    /// The expiration date formatted as a long localized date (e.g. "August 10, 2026"); empty when unset.
    var expirationDateDisplay: String { displayDate(from: expirationDate) }

    /// The issue date formatted as a long localized date (e.g. "August 10, 2026"); empty when unset.
    var issueDateDisplay: String { displayDate(from: issueDate) }
}

/// Formats a raw ISO-8601 date-only string (`yyyy-MM-dd`) as a long localized date for display
/// (e.g. "August 10, 2026"), or returns an empty string when the value is unset or unparsable.
///
/// - Note: Self-contained parsing is used here intentionally; PM-38360 introduces the shared
///   `DateFieldPicker` and date utilities that will replace these read-only fields.
private func displayDate(from isoString: String) -> String {
    guard !isoString.isEmpty, let date = isoDateOnlyParser.date(from: isoString) else { return "" }
    return date.formatted(date: .long, time: .omitted)
}

/// A parser for ISO-8601 date-only (`yyyy-MM-dd`) strings, fixed to UTC so a stored date is read
/// back as the same calendar day regardless of device locale.
private let isoDateOnlyParser: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()
