import Networking

// MARK: - ResponseValidationError

/// An error indicating that the response was invalid and didn't contain a successful HTTP status code.
///
struct ResponseValidationError: Error, Equatable {
    // MARK: Properties

    /// The received HTTP response.
    let response: HTTPResponse
}

// MARK: - ResponseValidationHandler

/// A `ResponseHandler` that validates that HTTP responses contain successful (2XX) HTTP status
/// codes or tries to parse the error otherwise.
///
class ResponseValidationHandler: ResponseHandler {
    func handle(_ response: inout HTTPResponse) async throws -> HTTPResponse {
        guard (200 ..< 300).contains(response.statusCode) else {
            // If the response can be parsed, throw an error containing the response message.
            if let errorResponse = try? ErrorResponseModel(response: response) {
                throw ServerError.error(errorResponse: errorResponse)
            }

            // Otherwise, throw a generic response validation error.
            throw ResponseValidationError(response: response)
        }
        return response
    }
}
