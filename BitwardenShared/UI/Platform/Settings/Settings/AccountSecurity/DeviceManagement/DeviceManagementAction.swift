import BitwardenKit

// MARK: - DeviceManagementAction

/// Actions that can be processed by a `DeviceManagementProcessor`.
///
enum DeviceManagementAction: Equatable {
    /// An action from a `DeviceRow`.
    case deviceRow(DeviceRowAction)

    /// Dismiss the sheet.
    case dismiss

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
