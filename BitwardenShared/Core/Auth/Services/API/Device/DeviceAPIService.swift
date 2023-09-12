// MARK: - DeviceAPIService

/// A protocol for an API service used to make device requests.
///
protocol DeviceAPIService {
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
    func knownDevice(email: String, deviceIdentifier: String) async throws -> Bool {
        let request = KnownDeviceRequest(email: email, deviceIdentifier: deviceIdentifier)
        let response = try await apiService.send(request)
        return response.isKnownDevice
    }
}
