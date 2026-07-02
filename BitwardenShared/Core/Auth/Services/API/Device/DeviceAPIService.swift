// MARK: - DeviceAPIService

/// A protocol for an API service used to make device requests.
///
protocol DeviceAPIService {
    /// Retrieves the current device by its app identifier.
    ///
    /// - Parameter appId: The unique app identifier for this device.
    /// - Returns: The `DeviceResponse` for the current device.
    ///
    func getCurrentDevice(appId: String) async throws -> DeviceResponse

    /// Retrieves the list of devices for the current user.
    ///
    /// - Returns: An array of `DeviceResponse` representing all devices.
    ///
    func getDevices() async throws -> [DeviceResponse]

    /// Queries the API to determine if this device was previously associated with the email address.
    ///
    /// - Parameters:
    ///   - email: The email being used to log into the app.
    ///   - deviceIdentifier: The unique identifier for this device.
    ///
    /// - Returns: `true` if this email has been associated with this device, `false` otherwise.
    ///
    func knownDevice(email: String, deviceIdentifier: String) async throws -> Bool
}

// MARK: - APIService

extension APIService: DeviceAPIService {
    func getCurrentDevice(appId: String) async throws -> DeviceResponse {
        try await apiService.send(CurrentDeviceRequest(appId: appId))
    }

    func getDevices() async throws -> [DeviceResponse] {
        let response = try await apiService.send(DevicesListRequest())
        return response.data
    }

    func knownDevice(email: String, deviceIdentifier: String) async throws -> Bool {
        let request = KnownDeviceRequest(email: email, deviceIdentifier: deviceIdentifier)
        let response = try await apiUnauthenticatedService.send(request)
        return response.isKnownDevice
    }
}
