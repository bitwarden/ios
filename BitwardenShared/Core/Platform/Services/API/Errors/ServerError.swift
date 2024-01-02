// MARK: - ServerError

/// An enumeration of server errors.
///
enum ServerError: Error, Equatable {
    /// A generic error.
    ///
    /// - Parameter errorResponse: The error response returned from the API request.
    ///
    case error(errorResponse: ErrorResponseModel)
}
