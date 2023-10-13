import Networking

@testable import BitwardenShared

class MockTokenService: TokenService {
    var accessToken: String? = "ACCESS_TOKEN"
    var refreshToken: String? = "REFRESH_TOKEN"

    func getAccessToken() async throws -> String {
        guard let accessToken else { throw StateServiceError.noActiveAccount }
        return accessToken
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
