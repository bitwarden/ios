import BitwardenKit
import BitwardenKitMocks
import Networking

@testable import AuthenticatorShared

extension APIService {
    convenience init(
        client: HTTPClient,
        flightRecorder: FlightRecorder = MockFlightRecorder(),
    ) {
        self.init(
            client: client,
            environmentService: MockEnvironmentService(),
            flightRecorder: flightRecorder,
        )
    }
}
