import Networking

// MARK: - ResponseValidationError

/// An error indicating that the response was invalid and didn't contain a successful HTTP status code.
///
public struct ResponseValidationError: NonLoggableError, Equatable {
    // MARK: Properties

    /// The received HTTP response.
    public let response: HTTPResponse

    // MARK: Initializers

    /// Initializes a `ResponseValidationError`.
    ///
    /// - Parameters:
    ///   - response: The received HTTP response.
    public init(response: HTTPResponse) {
        self.response = response
    }
}

// MARK: - ResponseValidationHandler

/// A `ResponseHandler` that validates that HTTP responses contain successful (2XX) HTTP status
/// codes or tries to parse the error otherwise.
///
public final class ResponseValidationHandler: ResponseHandler {
    /// Initializes a `ResponseValidationHandler`.
    public init() {}

    /// Handles receiving a `HTTPResponse`. The handler can view or modify the response before
    /// returning it to continue to handler chain.
    ///
    /// - Parameter response: The `HTTPResponse` that was received by the `HTTPClient`.
    /// - Returns: The original or modified `HTTPResponse`.
    ///
    public func handle(_ response: inout HTTPResponse) async throws -> HTTPResponse {
        guard (200 ..< 300).contains(response.statusCode) else {
            // If the response can be parsed, throw an error containing the response message.
            if let errorResponse = try? ErrorResponseModel(response: response) {
                throw ServerError.error(errorResponse: errorResponse)
            }

            // If the response can be parsed, throw an error containing the response message.
            if let validationErrorResponse = try? ResponseValidationErrorModel(response: response) {
                throw ServerError.validationError(validationErrorResponse: validationErrorResponse)
            }

            // Otherwise, throw a generic response validation error.
            throw ResponseValidationError(response: response)
        }
        return response
    }
}
