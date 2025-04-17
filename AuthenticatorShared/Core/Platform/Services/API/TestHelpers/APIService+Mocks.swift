import BitwardenKit
import BitwardenKitMocks
import Networking

@testable import AuthenticatorShared

extension APIService {
    convenience init(
        client: HTTPClient
    ) {
        self.init(
            client: client,
            environmentService: MockEnvironmentService()
        )
    }
}
