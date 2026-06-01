import BitwardenSdk
import BitwardenSdkMocks

@testable import AuthenticatorShared

class MockPlatformClientService: PlatformClientService {
    var fingerprintMaterialString: String?
    var fingerprintResult: Result<String, Error> = .success("a-fingerprint-phrase-string-placeholder")
    var featureFlags: [String: Bool] = [:]
    var loadFlagsError: Error?
    var stateMock = MockStateClientProtocol()
    var userFingerprintCalled = false

    func fingerprint(request req: BitwardenSdk.FingerprintRequest) throws -> String {
        try fingerprintResult.get()
    }

    func loadFlags(_ flags: [String: Bool]) throws {
        if let loadFlagsError {
            throw loadFlagsError
        }
        featureFlags = flags
    }

    func state() -> StateClientProtocol {
        stateMock
    }

    func userFingerprint(material fingerprintMaterial: String) throws -> String {
        fingerprintMaterialString = fingerprintMaterial
        userFingerprintCalled = true
        return try fingerprintResult.get()
    }
}
