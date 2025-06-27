import BitwardenKit

@testable import BitwardenShared

// MARK: - MockAccountTokenProvider

@MainActor
class MockAccountTokenProvider: AccountTokenProvider {
    var delegate: AccountTokenProviderDelegate?
    var getTokenResult: Result<String, Error> = .success("ACCESS_TOKEN")
    var refreshTokenResult: Result<Void, Error> = .success(())

    func getToken() async throws -> String {
        try getTokenResult.get()
    }

    func refreshToken() async throws {
        try refreshTokenResult.get()
    }

    func setDelegate(delegate: AccountTokenProviderDelegate) async {
        self.delegate = delegate
    }
}

// MARK: - MockAccountTokenProviderDelegate

class MockAccountTokenProviderDelegate: AccountTokenProviderDelegate {
    var onRefreshTokenErrorCalled = false
    var onRefreshTokenErrorResult: Result<Void, Error> = .success(())

    func onRefreshTokenError(error: any Error) async throws {
        onRefreshTokenErrorCalled = true
        try onRefreshTokenErrorResult.get()
    }
}
