import Foundation
import Networking

// MARK: - ErrorResponseModel

/// An error response returned from an API request.
///
struct ErrorResponseModel: Codable, Equatable {
    // MARK: Properties

    /// Validation errors returned from the API request.
    let validationErrors: [String: [String]]?

    /// The error message.
    let message: String

    // MARK: Methods

    /// A method that returns the specific validation error or an error message if the validation error is nil.
    ///
    /// - Returns: The validation error or an error message.
    ///
    func singleMessage() -> String {
        guard let validationErrors, !validationErrors.isEmpty else { return message }

        return validationErrors.values.first { values in
            !values.isEmpty
        }?.first ?? message
    }
}

// MARK: JSONResponse

extension ErrorResponseModel: JSONResponse {
    static let decoder = JSONDecoder.pascalOrSnakeCaseDecoder
}
