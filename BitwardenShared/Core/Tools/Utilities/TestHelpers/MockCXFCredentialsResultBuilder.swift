import BitwardenSdk

@testable import BitwardenShared

class MockCXFCredentialsResultBuilder: CXFCredentialsResultBuilder {
    var buildResult: [CXFCredentialsResult] = []

    func build(from ciphers: [Cipher]) -> [CXFCredentialsResult] {
        buildResult
    }
}
