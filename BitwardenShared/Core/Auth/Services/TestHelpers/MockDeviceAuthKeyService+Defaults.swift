@testable import BitwardenShared
@testable import BitwardenSharedMocks

extension MockDeviceAuthKeyService {
    /// Creates a `MockDeviceAuthKeyService` that reports no device auth key. The generated mock
    /// has no default return values, and the device auth key checks run in DEBUG builds without
    /// a feature flag, so tests that don't set up the mock would crash without this.
    ///
    static func withDefaults() -> MockDeviceAuthKeyService {
        let service = MockDeviceAuthKeyService()
        service.hasDeviceAuthKeyReturnValue = false
        service.isPasswordlessAccountReturnValue = false
        return service
    }
}
