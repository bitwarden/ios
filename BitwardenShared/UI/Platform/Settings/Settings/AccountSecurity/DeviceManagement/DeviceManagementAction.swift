import BitwardenKit

// MARK: - DeviceManagementAction

/// Actions that can be processed by a `DeviceManagementProcessor`.
///
enum DeviceManagementAction: Equatable {
    /// A device was tapped.
    case deviceTapped(DeviceListItem)

    /// Dismiss the sheet.
    case dismiss

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
