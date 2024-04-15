import BitwardenSdk

// MARK: MockTrustDeviceService

@testable import BitwardenShared

class MockTrustDeviceService: TrustDeviceService {
    var getDeviceKeyResult: Result<String, Error> = .success("DEVICE_KEY")
    var getShouldTrustDeviceResult: Result<Bool, Error> = .success(true)
    var isDeviceTrustedResult: Result<Bool, Error> = .success(true)
    var removeTrustedDeviceResult: Result<Void, Error> = .success(())
    var setShouldTrustDeviceResult: Result<Void, Error> = .success(())
    var shouldTrustDevice: Bool?
    var trustDeviceResult: Result<TrustDeviceResponse, Error> = .success(.fixture())
    var trustDeviceWithExistingKeysResult: Result<Void, Error> = .success(())
    var trustDeviceWithExistingKeysValue: TrustDeviceResponse?

    func getDeviceKey() async throws -> String? {
        try getDeviceKeyResult.get()
    }

    func trustDevice() async throws -> TrustDeviceResponse {
        try trustDeviceResult.get()
    }

    func trustDeviceIfNeeded() async throws -> TrustDeviceResponse? {
        if try await getShouldTrustDevice() {
            return try await trustDevice()
        }
        return nil
    }

    func trustDeviceWithExistingKeys(keys: TrustDeviceResponse) async throws {
        trustDeviceWithExistingKeysValue = keys
        try trustDeviceWithExistingKeysResult.get()
    }

    func removeTrustedDevice() async throws {
        try removeTrustedDeviceResult.get()
    }

    func getShouldTrustDevice() async throws -> Bool {
        try getShouldTrustDeviceResult.get()
    }

    func setShouldTrustDevice(_ value: Bool) async throws {
        shouldTrustDevice = value
        try setShouldTrustDeviceResult.get()
    }

    func isDeviceTrusted() async throws -> Bool {
        try isDeviceTrustedResult.get()
    }
}
