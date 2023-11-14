@testable import BitwardenShared

class MockCryptoService: CryptoService {
    var randomStringLength: Int?
    var randomStringResult: Result<String, Error> = .success("ku5eoyi3")

    func randomString(length: Int) throws -> String {
        randomStringLength = length
        return try randomStringResult.get()
    }
}
