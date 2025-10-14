import Foundation
import Networking

// MARK: - ErrorResponseModel

/// An error response returned from an API request.
///
public struct ErrorResponseModel: Codable, Equatable, Sendable {
    // MARK: Properties

    /// Validation errors returned from the API request.
    public let validationErrors: [String: [String]]?

    /// The error message.
    public let message: String

    // MARK: Initializers

    /// Initializes an `ErrorResponseModel`.
    ///
    /// - Parameters:
    ///   - validationErrors: Validation errors returned from the API request.
    ///   - message: The error message.
    public init(validationErrors: [String: [String]]?, message: String) {
        self.validationErrors = validationErrors
        self.message = message
    }

    // MARK: Methods

    /// A method that returns the specific validation error or an error message if the validation error is nil.
    ///
    /// - Returns: The validation error or an error message.
    ///
    public func singleMessage() -> String {
        guard let validationErrors, !validationErrors.isEmpty else { return message }

        return validationErrors.values.first { values in
            !values.isEmpty
        }?.first ?? message
    }
}

// MARK: JSONResponse

extension ErrorResponseModel: JSONResponse {
    public static let decoder = JSONDecoder.pascalOrSnakeCaseDecoder
}
