import LocalAuthentication

@testable import BitwardenShared

class MockLocalAuthService: LocalAuthService {
    var deviceAuthenticationStatus: DeviceAuthenticationStatus = .notDetermined
    var evaluateDeviceOwnerPolicyResult: Result<Bool, Error> = .success(true)

    func evaluateDeviceOwnerPolicy(
        _ suppliedContext: LAContext?,
        for deviceAuthStatus: DeviceAuthenticationStatus,
        because localizedReason: String
    ) async throws -> Bool {
        try evaluateDeviceOwnerPolicyResult.get()
    }

    func getDeviceAuthStatus(_ suppliedContext: LAContext?) -> BitwardenShared.DeviceAuthenticationStatus {
        deviceAuthenticationStatus
    }
}
