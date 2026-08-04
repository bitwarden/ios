// MARK: ViewPassportItemAction

/// An enum of actions for viewing a passport item.
///
enum ViewPassportItemAction: Equatable {
    /// Toggle for national identification number visibility changed.
    case toggleNationalIdentificationNumberVisibilityChanged(Bool) // swiftlint:disable:this identifier_name

    /// Toggle for passport number visibility changed.
    case togglePassportNumberVisibilityChanged(Bool)
}
