import BitwardenKit

extension ConfigService {
    /// Whether the device auth key flows are enabled.
    ///
    /// For the proof of concept, `FeatureFlag.deviceAuthKey` is always on in DEBUG builds, so the
    /// flows work against a server that doesn't turn the flag on. Release builds use the flag.
    ///
    /// - Parameter isPreAuth: If true, the call is coming before the user is authenticated.
    /// - Returns: Whether the device auth key flows are enabled.
    ///
    func isDeviceAuthKeyEnabled(isPreAuth: Bool = false) async -> Bool {
        #if DEBUG
        true
        #else
        await getFeatureFlag(.deviceAuthKey, isPreAuth: isPreAuth)
        #endif
    }
}
