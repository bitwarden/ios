import OSLog

// MARK: - HTTPLogger

/// A protocol for an object that can log HTTP request and responses.
///
public protocol HTTPLogger: Sendable {
    /// Logs the details of a `HTTPRequest`.
    ///
    /// - Parameter httpRequest: The `HTTPRequest` to log the details of.
    ///
    func logRequest(_ httpRequest: HTTPRequest) async

    /// Logs the details of a `HTTPResponse`.
    ///
    /// - Parameter httpResponse: The `HTTPResponse` to log the details of.
    ///
    func logResponse(_ httpResponse: HTTPResponse) async
}

// MARK: - OSLogHTTPLogger

/// An object that handles logging HTTP requests and responses to OSLog.
///
public final class OSLogHTTPLogger: HTTPLogger {
    // MARK: Initialization

    public init() {}

    // MARK: HTTPLogger

    public func logRequest(_ httpRequest: HTTPRequest) async {
        let formattedBody = formattedBody(httpRequest.body)
        let formattedHeaders = formattedHeaders(httpRequest.headers)
        Logger.networking.info("""
        Request \(httpRequest.requestID): \(httpRequest.method.rawValue) \(httpRequest.url)
        Headers: \(formattedHeaders)
        Body: \(formattedBody)
        """)
    }

    public func logResponse(_ httpResponse: HTTPResponse) async {
        let formattedBody = formattedBody(httpResponse.body)
        let formattedHeaders = formattedHeaders(httpResponse.headers)
        Logger.networking.info("""
        Response \(httpResponse.requestID): \(httpResponse.url) \(httpResponse.statusCode)
        Headers: \(formattedHeaders)
        Body: \(formattedBody)
        """)
    }

    // MARK: Private

    /// Formats the data in the body of a request or response for logging.
    ///
    /// - Parameter data: The data from the body of a request or response to format.
    /// - Returns: A string containing the formatted body data.
    ///
    private func formattedBody(_ data: Data?) -> String {
        guard let data, !data.isEmpty else { return "(empty)" }

        if let dataString = String(data: data, encoding: .utf8) {
            return dataString
        }

        return data.debugDescription
    }

    /// Formats the headers of a request or response for logging.
    ///
    /// - Parameter headers: The headers from the body of a request or response to format.
    /// - Returns: A string containing the formatted headers.
    ///
    private func formattedHeaders(_ headers: [String: String]) -> String {
        guard !headers.isEmpty else { return "(empty)" }

        let headersString = headers
            .map { "  \($0): \($1)" }
            .joined(separator: "\n")

        return """
        [
        \(headersString)
        ]
        """
    }
}
