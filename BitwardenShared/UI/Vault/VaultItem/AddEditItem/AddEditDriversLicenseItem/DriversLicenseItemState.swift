import BitwardenSdk
import Foundation

// MARK: - DriversLicenseItemState

/// A model for a driver's license item.
///
struct DriversLicenseItemState: Equatable {
    /// The date of birth on the license.
    var dateOfBirth: Date?

    /// The expiration date of the license.
    var expirationDate: Date?

    /// The first name on the license.
    var firstName: String = ""

    /// Whether the license number is visible.
    var isLicenseNumberVisible: Bool = false

    /// The issue date of the license.
    var issueDate: Date?

    /// The authority that issued the license.
    var issuingAuthority: String = ""

    /// The country that issued the license.
    var issuingCountry: String = ""

    /// The state or province that issued the license.
    var issuingState: String = ""

    /// The last name on the license.
    var lastName: String = ""

    /// The class of the license.
    var licenseClass: String = ""

    /// The number of the license.
    var licenseNumber: String = ""

    /// The middle name on the license.
    var middleName: String = ""
}

extension DriversLicenseItemState {
    var driversLicenseView: DriversLicenseView {
        .init(
            firstName: firstName.nilIfEmpty,
            middleName: middleName.nilIfEmpty,
            lastName: lastName.nilIfEmpty,
            dateOfBirth: dateOfBirth,
            licenseNumber: licenseNumber.nilIfEmpty,
            issuingCountry: issuingCountry.nilIfEmpty,
            issuingState: issuingState.nilIfEmpty,
            issueDate: issueDate,
            expirationDate: expirationDate,
            issuingAuthority: issuingAuthority.nilIfEmpty,
            licenseClass: licenseClass.nilIfEmpty,
        )
    }
}

// MARK: AddEditDriversLicenseItemState

extension DriversLicenseItemState: AddEditDriversLicenseItemState {}
