import BitwardenKit
import BitwardenKitMocks
import Networking

@testable import AuthenticatorShared

extension APIService {
    convenience init(
        client: HTTPClient,
        environmentService: EnvironmentService = MockEnvironmentService()
    ) {
        self.init(
            client: client,
            environmentService: environmentService
        )
    }
}
