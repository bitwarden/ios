@testable import Networking

class MockTokenProvider: TokenProvider {
    enum TokenProviderError: Error {
        case noTokenResults
    }

    var getTokenCallCount = 0
    var tokenResults: [Result<String, Error>] = [.success("ACCESS_TOKEN")]
    var refreshTokenResult: Result<Void, Error> = .success(())
    var refreshTokenCallCount = 0

    func getToken() async throws -> String {
        getTokenCallCount += 1
        guard !tokenResults.isEmpty else { throw TokenProviderError.noTokenResults }
        return try tokenResults.removeFirst().get()
    }

    func refreshToken() async throws {
        refreshTokenCallCount += 1
        try refreshTokenResult.get()
    }
}
