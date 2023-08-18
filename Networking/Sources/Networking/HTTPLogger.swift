import OSLog

/// An object that handles logging HTTP requests and responses.
///
class HTTPLogger {
    /// Logs the details of a `HTTPRequest`.
    ///
    /// - Parameter httpRequest: The `HTTPRequest` to log the details of.
    ///
    func logRequest(_ httpRequest: HTTPRequest) {
        let formattedBody = formattedBody(httpRequest.body)
        Logger.networking.info("""
            Request \(httpRequest.requestID): \(httpRequest.method.rawValue) \(httpRequest.url)
            Body: \(formattedBody)
            """
        )
    }

    /// Logs the details of a `HTTPResponse`.
    ///
    /// - Parameter httpResponse: The `HTTPResponse` to log the details of.
    ///
    func logResponse(_ httpResponse: HTTPResponse) {
        let formattedBody = formattedBody(httpResponse.body)
        Logger.networking.info("""
            Response \(httpResponse.requestID): \(httpResponse.url) \(httpResponse.statusCode)
            Body: \(formattedBody)
            """
        )
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
}
