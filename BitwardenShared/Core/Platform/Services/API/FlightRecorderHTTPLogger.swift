import Networking

// MARK: FlightRecorderHTTPLogger

/// An `HTTPLogger` that logs HTTP requests and responses to the flight recorder.
///
final class FlightRecorderHTTPLogger: HTTPLogger {
    // MARK: Properties

    /// The service used by the application for recording temporary debug logs.
    private let flightRecorder: FlightRecorder

    // MARK: Initialization

    /// Initialize a `FlightRecorderHTTPLogger`.
    ///
    /// - Parameter flightRecorder: The service used by the application for recording temporary debug logs.
    ///
    init(flightRecorder: FlightRecorder) {
        self.flightRecorder = flightRecorder
    }

    // MARK: HTTPLogger

    func logRequest(_ httpRequest: HTTPRequest) async {
        await flightRecorder.log(
            "Request \(httpRequest.requestID): \(httpRequest.method.rawValue) \(httpRequest.url)"
        )
    }

    func logResponse(_ httpResponse: HTTPResponse) async {
        await flightRecorder.log(
            "Response \(httpResponse.requestID): \(httpResponse.url) \(httpResponse.statusCode)"
        )
    }
}
