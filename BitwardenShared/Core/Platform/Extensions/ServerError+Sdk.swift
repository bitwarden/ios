import BitwardenKit
import BitwardenSdk
import Foundation
import Networking

// MARK: - ServerError

extension ServerError {
    // MARK: Initialization

    /// Initializes a `ServerError` from the message of an SDK API error, if the message contains an
    /// error response from the server.
    ///
    /// The SDK flattens API errors into a message in the format
    /// `error in response: status code <status>: <response body>`. If the response body can be
    /// decoded as an `ErrorResponseModel`, this returns the equivalent `ServerError` that the app
    /// throws when it makes the request itself, so the server's message is shown to the user.
    ///
    /// - Parameter sdkApiErrorMessage: The message of an SDK API error.
    ///
    init?(sdkApiErrorMessage: String) {
        let responsePrefix = "error in response: status code "
        guard let prefixRange = sdkApiErrorMessage.range(of: responsePrefix),
              let bodySeparatorRange = sdkApiErrorMessage.range(
                  of: ": ",
                  range: prefixRange.upperBound ..< sdkApiErrorMessage.endIndex,
              ),
              let errorResponse = try? ErrorResponseModel.decoder.decode(
                  ErrorResponseModel.self,
                  from: Data(sdkApiErrorMessage[bodySeparatorRange.upperBound...].utf8),
              )
        else {
            return nil
        }
        self = .error(errorResponse: errorResponse)
    }

    // MARK: Methods

    /// Performs an SDK operation, converting any API error containing a server error response into
    /// a `ServerError`.
    ///
    /// - Parameter operation: The SDK operation to perform.
    /// - Returns: The result of the operation.
    /// - Throws: A `ServerError` if the server rejected the request, otherwise the original error.
    ///
    static func mappingSdkApiErrors<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as BitwardenSdk.BitwardenError {
            guard let message = error.apiErrorMessage,
                  let serverError = ServerError(sdkApiErrorMessage: message)
            else {
                throw error
            }
            throw serverError
        }
    }
}

// MARK: - BitwardenSdk.BitwardenError

extension BitwardenSdk.BitwardenError {
    /// The message of the underlying API error, if this error was caused by an API request made by
    /// a cipher operation in the SDK.
    var apiErrorMessage: String? {
        switch self {
        case let .CreateCipher(.Api(message)),
             let .EditCipher(.Api(message)):
            message
        default:
            nil
        }
    }
}
