@testable import BitwardenShared
@testable import BitwardenSharedMocks

extension MockDeviceAuthKeyService {
    /// Creates a `MockDeviceAuthKeyService` that reports no device auth key. The generated mock
    /// has no default return values, so tests that don't set it up would crash without this.
    ///
    static func withDefaults() -> MockDeviceAuthKeyService {
        let service = MockDeviceAuthKeyService()
        service.hasDeviceAuthKeyReturnValue = false
        service.isPasswordlessAccountReturnValue = false
        return service
    }
}
