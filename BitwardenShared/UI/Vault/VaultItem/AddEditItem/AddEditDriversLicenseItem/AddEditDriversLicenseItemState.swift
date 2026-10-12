import Foundation

// MARK: AddEditDriversLicenseItemState

/// A protocol for a sendable type that models a Driver's License Item in it's add/edit state.
///
protocol AddEditDriversLicenseItemState: Equatable, Sendable {
    /// The date of birth on the license.
    var dateOfBirth: Date? { get set }

    /// The expiration date of the license.
    var expirationDate: Date? { get set }

    /// The first name on the license.
    var firstName: String { get set }

    /// Whether the license number is visible.
    var isLicenseNumberVisible: Bool { get set }

    /// The issue date of the license.
    var issueDate: Date? { get set }

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
