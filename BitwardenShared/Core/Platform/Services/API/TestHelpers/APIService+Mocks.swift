import Networking

@testable import BitwardenShared

extension APIService {
    convenience init(
        client: HTTPClient,
        environmentService: EnvironmentService = MockEnvironmentService(),
        stateService: StateService = MockStateService()
    ) {
        self.init(
            client: client,
            environmentService: environmentService,
            stateService: stateService,
            tokenService: MockTokenService()
        )
    }
}
