import BitwardenKit
import BitwardenKitMocks
import Networking

@testable import BitwardenShared

extension APIService {
    convenience init(
        accountTokenProvider: AccountTokenProvider? = nil,
        client: HTTPClient,
        environmentService: EnvironmentService = MockEnvironmentService(),
        flightRecorder: FlightRecorder = MockFlightRecorder(),
        stateService: StateService = MockStateService(),
    ) {
        self.init(
            accountTokenProvider: accountTokenProvider,
            client: client,
            environmentService: environmentService,
            flightRecorder: flightRecorder,
            stateService: stateService,
            tokenService: MockTokenService(),
        )
    }
}
