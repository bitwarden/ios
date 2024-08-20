import Networking

@testable import BitwardenShared

class MockTokenService: TokenService {
    var accessToken: String? = "ACCESS_TOKEN"
    var getIsExternalResult: Result<Bool, Error> = .success(false)
    var refreshToken: String? = "REFRESH_TOKEN"

    func getAccessToken() async throws -> String {
        guard let accessToken else { throw StateServiceError.noActiveAccount }
        return accessToken
    }

    func getIsExternal() async throws -> Bool {
        try getIsExternalResult.get()
    }

    func getRefreshToken() async throws -> String {
        guard let refreshToken else { throw StateServiceError.noActiveAccount }
        return refreshToken
    }

    func setTokens(accessToken: String, refreshToken: String) async {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
