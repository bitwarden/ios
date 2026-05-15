import BitwardenKit

// MARK: - DeviceManagementState

/// The state used to present the `DeviceManagementView`.
///
struct DeviceManagementState: Equatable, Sendable {
    // MARK: Properties

    /// The loading state of the device management screen.
    var loadingState: LoadingState<[DeviceListItem]> = .loading(nil)

    /// A toast message to show in the view.
    var toast: Toast?

    /// The ID of the current device.
    var currentDeviceId: String?
}
