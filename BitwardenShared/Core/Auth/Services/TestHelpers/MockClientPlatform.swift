import BitwardenSdk

@testable import BitwardenShared

class MockClientPlatform: ClientPlatformProtocol {
    var fingerprintMaterialString: String?
    var fingerprintResult: Result<String, Error> = .success("a-fingerprint-phrase-string-placeholder")
    var userFingerprintCalled = false

    func fingerprint(req: BitwardenSdk.FingerprintRequest) async throws -> String {
        try fingerprintResult.get()
    }

    func userFingerprint(fingerprintMaterial: String) async throws -> String {
        fingerprintMaterialString = fingerprintMaterial
        userFingerprintCalled = true
        return try fingerprintResult.get()
    }
}
