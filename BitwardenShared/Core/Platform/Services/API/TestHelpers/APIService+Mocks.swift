import Networking

@testable import BitwardenShared

extension APIService {
    convenience init(
        client: HTTPClient,
        environmentService: EnvironmentService = MockEnvironmentService()
    ) {
        self.init(
            client: client,
            environmentService: environmentService,
            tokenService: MockTokenService()
        )
    }
}
