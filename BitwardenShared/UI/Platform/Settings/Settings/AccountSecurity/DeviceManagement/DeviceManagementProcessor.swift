import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - DeviceManagementProcessor

/// The processor used to manage state and handle actions for the `DeviceManagementView`.
///
final class DeviceManagementProcessor: StateProcessor<
    DeviceManagementState,
    DeviceManagementAction,
    DeviceManagementEffect,
> {
    // MARK: Types

    typealias Services = HasAppIdService
        & HasAuthService
        & HasConfigService
        & HasDeviceAPIService
        & HasErrorReporter
        & HasTimeProvider

    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services used by the processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a `DeviceManagementProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        services: Services,
        state: DeviceManagementState,
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: DeviceManagementEffect) async {
        switch effect {
        case .loadData:
            await loadData()
        }
    }

    override func receive(_ action: DeviceManagementAction) {
        switch action {
        case let .deviceTapped(device):
            handleDeviceTapped(device)
        case .dismiss:
            coordinator.navigate(to: .dismiss, context: self)
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }

    // MARK: Private Methods

    /// Handles when a device is tapped.
    ///
    /// - Parameter device: The device that was tapped.
    ///
    private func handleDeviceTapped(_ device: DeviceListItem) {
        guard let pendingRequest = device.pendingRequest else { return }
        coordinator.navigate(to: .loginRequest(pendingRequest), context: self)
    }

    /// Loads the device data.
    ///
    private func loadData() async {
        do {
            // Get the current device's app ID.
            let appId = await services.appIdService.getOrCreateAppId()

            // Fetch all devices and the current device in parallel.
            async let devicesTask = services.deviceAPIService.getDevices()
            async let currentDeviceTask = services.deviceAPIService.getCurrentDevice(appId: appId)
            async let pendingRequestsTask = services.authService.getPendingLoginRequests()

            let (devices, currentDevice, pendingRequests) = try await (
                devicesTask,
                currentDeviceTask,
                pendingRequestsTask,
            )

            state.currentDeviceId = currentDevice.id

            // Create device list items and mark current session.
            var deviceItems = devices.map { device in
                var item = DeviceListItem(device: device, timeProvider: services.timeProvider)
                item.isCurrentSession = device.id == currentDevice.id
                return item
            }

            // Match pending requests to devices.
            deviceItems = matchPendingRequestsToDevices(deviceItems, pendingRequests: pendingRequests)

            // Sort devices: current session first, then pending requests, then by activity.
            deviceItems.sort { lhs, rhs in
                // Current session always first.
                if lhs.isCurrentSession != rhs.isCurrentSession {
                    return lhs.isCurrentSession
                }
                // Devices with pending requests second.
                if lhs.hasPendingRequest != rhs.hasPendingRequest {
                    return lhs.hasPendingRequest
                }
                // Sort by last activity date descending, with nil dates last.
                switch (lhs.lastActivityDate, rhs.lastActivityDate) {
                case let (lhsDate?, rhsDate?):
                    return lhsDate > rhsDate
                case (nil, _?):
                    return false
                case (_?, nil):
                    return true
                case (nil, nil):
                    // Fall back to creation date.
                    return lhs.firstLogin > rhs.firstLogin
                }
            }

            state.loadingState = .data(deviceItems)
        } catch {
            state.loadingState = .data([])
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }

    /// Matches the most recent pending login request to its corresponding device.
    ///
    /// - Parameters:
    ///   - devices: The list of device items.
    ///   - pendingRequests: The list of pending login requests.
    /// - Returns: The updated list of device items with the most recent pending request matched.
    ///
    private func matchPendingRequestsToDevices(
        _ devices: [DeviceListItem],
        pendingRequests: [LoginRequest],
    ) -> [DeviceListItem] {
        var updatedDevices = devices

        // Sort pending requests by creation date descending to get most recent first.
        let sortedRequests = pendingRequests.sorted { $0.creationDate > $1.creationDate }

        for request in sortedRequests {
            // Try to match by device platform name.
            if let index = updatedDevices.firstIndex(where: { device in
                device.deviceType.platform.lowercased() == request.requestDeviceType.lowercased()
            }) {
                // Only set if no pending request has been set yet (keeps the most recent).
                if updatedDevices[index].pendingRequest == nil {
                    updatedDevices[index].pendingRequest = request
                    updatedDevices[index].hasPendingRequest = true
                }
            }
        }

        return updatedDevices
    }
}

// MARK: - LoginRequestDelegate

extension DeviceManagementProcessor: LoginRequestDelegate {
    /// Update the data and display a success toast after a login request has been answered.
    func loginRequestAnswered(approved: Bool) {
        Task { await loadData() }
        state.toast = Toast(title: approved ? Localizations.loginApproved : Localizations.logInDenied)
    }
}
