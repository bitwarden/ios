import Foundation

// MARK: AddEditPassportItemAction

/// An enum of actions for adding or editing a passport item in its add/edit state.
///
enum AddEditPassportItemAction: Equatable, Sendable {
    /// The birth place changed.
    case birthPlaceChanged(String)

    /// The date of birth changed.
    case dateOfBirthChanged(Date?)

    /// The expiration date changed.
    case expirationDateChanged(Date?)

    /// The given name (first name) on the passport changed.
    case givenNameChanged(String)

    /// The issue date changed.
    case issueDateChanged(Date?)

    /// The issuing authority/office changed.
    case issuingAuthorityChanged(String)

    /// The issuing country changed.
    case issuingCountryChanged(String)

    /// The national identification number changed.
    case nationalIdentificationNumberChanged(String)

    /// The nationality changed.
    case nationalityChanged(String)

    /// The passport number changed.
    case passportNumberChanged(String)

    /// The passport type changed.
    case passportTypeChanged(String)

    /// The sex changed.
    case sexChanged(String)

    /// The surname (last name) on the passport changed.
    case surnameChanged(String)

    /// Toggle for national identification number visibility changed.
    case toggleNationalIdentificationNumberVisibilityChanged(Bool) // swiftlint:disable:this identifier_name

    /// Toggle for passport number visibility changed.
    case togglePassportNumberVisibilityChanged(Bool)
}
