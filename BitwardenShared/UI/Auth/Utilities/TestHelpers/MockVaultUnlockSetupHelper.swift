@testable import BitwardenShared

class MockVaultUnlockSetupHelper: VaultUnlockSetupHelper {
    var setBiometricUnlockCalled = false
    var setBiometricUnlockStatus: BiometricsUnlockStatus?

    var setPinUnlockCalled = false
    var setPinUnlockResult: Bool?

    func setBiometricUnlock(enabled: Bool, showAlert: @escaping (Alert) -> Void) async -> BiometricsUnlockStatus? {
        setBiometricUnlockCalled = true
        return setBiometricUnlockStatus
    }

    func setPinUnlock(enabled: Bool, showAlert: @escaping (Alert) -> Void) async -> Bool {
        setPinUnlockCalled = true
        return setPinUnlockResult ?? !enabled
    }
}
