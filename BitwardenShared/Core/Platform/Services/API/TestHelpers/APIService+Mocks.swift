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
        // swiftlint:disable:next line_length
        serverCommunicationConfigClientSingleton: ServerCommunicationConfigClientSingleton = MockServerCommunicationConfigClientSingleton(),
        stateService: StateService = MockStateService(),
    ) {
        self.init(
            accountTokenProvider: accountTokenProvider,
            client: client,
            environmentService: environmentService,
            flightRecorder: flightRecorder,
            serverCommunicationConfigClientSingleton: { serverCommunicationConfigClientSingleton },
            stateService: stateService,
            tokenService: MockTokenService(),
        )
    }
}
