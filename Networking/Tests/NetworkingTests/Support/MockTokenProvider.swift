@testable import Networking

@MainActor
class MockTokenProvider: TokenProvider {
    enum TokenProviderError: Error {
        case noTokenResults
    }

    var getTokenCallCount = 0
    var tokenResults: [Result<String, Error>] = [.success("ACCESS_TOKEN")]
    var refreshTokenResult: Result<String, Error> = .success("ACCESS_TOKEN")
    var refreshTokenCallCount = 0

    func getToken() async throws -> String {
        getTokenCallCount += 1
        guard !tokenResults.isEmpty else { throw TokenProviderError.noTokenResults }
        return try tokenResults.removeFirst().get()
    }

    func refreshToken() async throws -> String {
        refreshTokenCallCount += 1
        return try refreshTokenResult.get()
    }
}
