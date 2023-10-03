import Networking

@testable import BitwardenShared

extension APIService {
    convenience init(
        baseUrlService: BaseUrlService = DefaultBaseUrlService(baseUrl: .example),
        client: HTTPClient
    ) {
        self.init(baseUrlService: baseUrlService, client: client, tokenService: MockTokenService())
    }
}
