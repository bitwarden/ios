import BitwardenKit
import BitwardenKitMocks
import Networking

@testable import AuthenticatorShared

extension APIService {
    convenience init(
        client: HTTPClient,
        flightRecorder: FlightRecorder = MockFlightRecorder(),
        userAgentBuilder: UserAgentBuilder = UserAgentBuilder(
            appName: "TestApp",
            appVersion: "1.0",
            systemDevice: MockSystemDevice(),
        ),
    ) {
        self.init(
            client: client,
            environmentService: MockEnvironmentService(),
            flightRecorder: flightRecorder,
            userAgentBuilder: userAgentBuilder,
        )
    }
}
