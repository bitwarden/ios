import Foundation
import Networking

// MARK: - ResponseValidationErrorModel

/// An Response validation error returned from an API request.
///
public struct ResponseValidationErrorModel: Codable, Equatable, Sendable {
    // MARK: Properties

    /// A string that represents the error code.
    public let error: String

    /// A string that provides a description of the error.
    public let errorDescription: String?

    /// An `ErrorModel` object that provides more details about the error.
    public let errorModel: ErrorModel

    /// Public instance of synthesized initializer.
    public init(error: String, errorDescription: String?, errorModel: ErrorModel) {
        self.error = error
        self.errorDescription = errorDescription
        self.errorModel = errorModel
    }
}

public struct ErrorModel: Codable, Equatable, Sendable {
    // MARK: Properties

    /// A string that provides a message about the error.
    public let message: String

    /// A string that represents an object associated with the error.
    public let object: String

    /// Public instance of synthesized initializer.
    public init(message: String, object: String) {
        self.message = message
        self.object = object
    }
}

// MARK: JSONResponse

extension ResponseValidationErrorModel: JSONResponse {
    public static let decoder = JSONDecoder.pascalOrSnakeCaseDecoder
}
