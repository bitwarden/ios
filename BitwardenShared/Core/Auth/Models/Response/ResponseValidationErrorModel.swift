import Foundation
import Networking

// MARK: - ResponseValidationErrorModel

/// An Response validation error  returned from an API request.
///
struct ResponseValidationErrorModel: Codable, Equatable {
    /// Coding keys for the this  struct. These keys match the keys in the JSON response.
    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case errorModel = "ErrorModel"
    }

    // MARK: Properties

    /// A string that represents the error code.
    let error: String
    /// A string that provides a description of the error.
    let errorDescription: String
    /// An `ErrorModel` object that provides more details about the error.
    let errorModel: ErrorModel
}

struct ErrorModel: Codable, Equatable {
    /// Coding keys for the this  struct. These keys match the keys in  the JSON response.
    enum CodingKeys: String, CodingKey {
        case message = "Message"
        case object = "Object"
    }

    // MARK: Properties

    /// A string that provides a message about the error.
    let message: String
    /// A string that represents an object associated with the error.
    let object: String
}

// MARK: JSONResponse

extension ResponseValidationErrorModel: JSONResponse {}
