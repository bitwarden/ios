import BitwardenSdk

@testable import BitwardenShared

class MockPlatformClientService: PlatformClientService {
    var fido2Mock = MockClientFido2Service()
    var fingerprintMaterialString: String?
    var fingerprintResult: Result<String, Error> = .success("a-fingerprint-phrase-string-placeholder")
    var featureFlags: [String: Bool] = [:]
    var loadFlagsError: Error?
    var stateMock = MockStateClient()
    var userFingerprintCalled = false

    func fido2() -> ClientFido2Service {
        fido2Mock
    }

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
