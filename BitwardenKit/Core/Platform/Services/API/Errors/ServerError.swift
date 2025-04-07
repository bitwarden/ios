import Foundation

// MARK: - ServerError

/// An enumeration of server errors.
///
enum ServerError: Error, Equatable, CustomNSError {
    /// A generic error.
    ///
    /// - Parameter errorResponse: The error response returned from the API request.
    ///
    case error(errorResponse: ErrorResponseModel)

    /// A validation error.
    ///
    /// - Parameter validationErrorResponse: The validation error response returned from the API request.
    ///
    case validationError(validationErrorResponse: ResponseValidationErrorModel)

    /// A computed property that returns an error message based on the case.
    var message: String {
        switch self {
        case let .error(errorResponse):
            errorResponse.singleMessage()
        case let .validationError(validationErrorResponse):
            validationErrorResponse.errorModel.message
        }
    }

    /// The user-info dictionary.
    public var errorUserInfo: [String: Any] {
        ["Message": message]
    }
}
