import BitwardenSdk

// MARK: - DriversLicenseItemState

/// A model for a driver's license item.
///
struct DriversLicenseItemState: Equatable {
    /// The date of birth on the license, held as a raw ISO string.
    var dateOfBirth: String = ""

    /// The expiration date of the license, held as a raw ISO string.
    var expirationDate: String = ""

    /// The first name on the license.
    var firstName: String = ""

    /// Whether the license number is visible.
    var isLicenseNumberVisible: Bool = false

    /// The issue date of the license, held as a raw ISO string.
    var issueDate: String = ""

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
            dateOfBirth: dateOfBirth.nilIfEmpty,
            licenseNumber: licenseNumber.nilIfEmpty,
            issuingCountry: issuingCountry.nilIfEmpty,
            issuingState: issuingState.nilIfEmpty,
            issueDate: issueDate.nilIfEmpty,
            expirationDate: expirationDate.nilIfEmpty,
            issuingAuthority: issuingAuthority.nilIfEmpty,
            licenseClass: licenseClass.nilIfEmpty,
        )
    }
}

// MARK: AddEditDriversLicenseItemState

extension DriversLicenseItemState: AddEditDriversLicenseItemState {}
