import BitwardenKit
import BitwardenKitMocks
import Networking

@testable import BitwardenShared

extension APIService {
    convenience init(
        accountTokenProvider: AccountTokenProvider? = nil,
        activeAccountStateProvider: MockActiveAccountStateProvider = MockActiveAccountStateProvider(),
        client: HTTPClient,
        environmentService: EnvironmentService = MockEnvironmentService(),
        errorReporter: ErrorReporter = MockErrorReporter(),
        flightRecorder: FlightRecorder = MockFlightRecorder(),
        // swiftlint:disable:next line_length
        serverCommunicationConfigClientSingleton: ServerCommunicationConfigClientSingleton = MockServerCommunicationConfigClientSingleton(),
        stateService: StateService = MockStateService(),
        userAgentBuilder: UserAgentBuilder = UserAgentBuilder(
            appName: "TestApp",
            appVersion: "1.0",
            systemDevice: MockSystemDevice(),
        ),
    ) {
        self.init(
            accountTokenProvider: accountTokenProvider,
            activeAccountStateProvider: activeAccountStateProvider,
            client: client,
            environmentService: environmentService,
            errorReporter: errorReporter,
            flightRecorder: flightRecorder,
            serverCommunicationConfigClientSingleton: { serverCommunicationConfigClientSingleton },
            stateService: stateService,
            tokenService: MockTokenService(),
            userAgentBuilder: userAgentBuilder,
        )
    }
}
