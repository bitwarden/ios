// MARK: AddEditDriversLicenseItemAction

/// An enum of actions for adding or editing a driver's license Item in its add/edit state.
///
enum AddEditDriversLicenseItemAction: Equatable, Sendable {
    /// The first name on the license changed.
    case firstNameChanged(String)

    /// The issuing authority changed.
    case issuingAuthorityChanged(String)

    /// The issuing country changed.
    case issuingCountryChanged(String)

    /// The issuing state or province changed.
    case issuingStateChanged(String)

    /// The last name on the license changed.
    case lastNameChanged(String)

    /// The license class changed.
    case licenseClassChanged(String)

    /// The license number changed.
    case licenseNumberChanged(String)

    /// The middle name on the license changed.
    case middleNameChanged(String)

    /// Toggle for license number visibility changed.
    case toggleLicenseNumberVisibilityChanged(Bool)
}
