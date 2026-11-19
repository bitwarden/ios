// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenSdk
import TestHelpers
import Testing

@testable import BitwardenShared

// MARK: - ServerErrorSdkTests

struct ServerErrorSdkTests {
    // MARK: Properties

    /// An SDK API error message for an out of date cipher, in the format the SDK produces.
    static let outOfDateMessage = """
    error in response: status code 400 Bad Request: {"message":"The cipher you are updating is out \
    of date. Please save your work, sync your vault, and try again.","validationErrors":null,\
    "exceptionMessage":null,"exceptionStackTrace":null,"innerExceptionMessage":null,"object":"error"}
    """

    // MARK: Tests - init(sdkApiErrorMessage:)

    /// `init(sdkApiErrorMessage:)` creates a `ServerError` from the server's error response.
    @Test
    func init_sdkApiErrorMessage_errorResponse() {
        let subject = ServerError(sdkApiErrorMessage: Self.outOfDateMessage)

        #expect(subject == .error(errorResponse: ErrorResponseModel(
            validationErrors: nil,
            message: "The cipher you are updating is out of date. Please save your work, sync your vault, "
                + "and try again.",
        )))
    }

    /// `init(sdkApiErrorMessage:)` uses the first validation error as the message.
    @Test
    func init_sdkApiErrorMessage_validationErrors() {
        let subject = ServerError(sdkApiErrorMessage: """
        error in response: status code 400 Bad Request: {"message":"The model state is invalid.",\
        "validationErrors":{"Name":["The Name field is required."]},"object":"error"}
        """)

        #expect(subject?.message == "The Name field is required.")
    }

    /// `init(sdkApiErrorMessage:)` returns `nil` if the response body isn't an error response.
    @Test
    func init_sdkApiErrorMessage_invalidBody() {
        #expect(ServerError(sdkApiErrorMessage: "error in response: status code 500 Internal Server Error: ") == nil)
        #expect(ServerError(sdkApiErrorMessage: "error in response: status code 502 Bad Gateway: <html>") == nil)
    }

    /// `init(sdkApiErrorMessage:)` returns `nil` if the message isn't for an error response.
    @Test
    func init_sdkApiErrorMessage_notResponseError() {
        #expect(ServerError(sdkApiErrorMessage: "error in reqwest: error sending request") == nil)
        #expect(ServerError(sdkApiErrorMessage: "") == nil)
    }

    // MARK: Tests - mappingSdkApiErrors(_:)

    /// `mappingSdkApiErrors(_:)` returns the result of the operation.
    @Test
    func mappingSdkApiErrors_success() async throws {
        let result = try await ServerError.mappingSdkApiErrors { "result" }
        #expect(result == "result")
    }

    /// `mappingSdkApiErrors(_:)` converts a create cipher API error to a `ServerError`.
    @Test
    func mappingSdkApiErrors_createCipherApiError() async throws {
        let serverError = try #require(ServerError(sdkApiErrorMessage: Self.outOfDateMessage))
        await #expect(throws: serverError) {
            try await ServerError.mappingSdkApiErrors {
                throw BitwardenSdk.BitwardenError.CreateCipher(.Api(message: Self.outOfDateMessage))
            }
        }
    }

    /// `mappingSdkApiErrors(_:)` converts an edit cipher API error to a `ServerError`.
    @Test
    func mappingSdkApiErrors_editCipherApiError() async throws {
        let serverError = try #require(ServerError(sdkApiErrorMessage: Self.outOfDateMessage))
        await #expect(throws: serverError) {
            try await ServerError.mappingSdkApiErrors {
                throw BitwardenSdk.BitwardenError.EditCipher(.Api(message: Self.outOfDateMessage))
            }
        }
    }

    /// `mappingSdkApiErrors(_:)` converts the API errors of the other SDK cipher operations to a
    /// `ServerError`.
    @Test(arguments: [
        BitwardenSdk.BitwardenError.Cipher(.Api(message: Self.outOfDateMessage)),
        BitwardenSdk.BitwardenError.DeleteCipher(.Api(message: Self.outOfDateMessage)),
        BitwardenSdk.BitwardenError.RestoreCipher(.Api(message: Self.outOfDateMessage)),
    ])
    func mappingSdkApiErrors_cipherOperationApiErrors(error: BitwardenSdk.BitwardenError) async throws {
        let serverError = try #require(ServerError(sdkApiErrorMessage: Self.outOfDateMessage))
        await #expect(throws: serverError) {
            try await ServerError.mappingSdkApiErrors { throw error }
        }
    }

    /// `mappingSdkApiErrors(_:)` rethrows an API error that doesn't contain a server error response.
    @Test
    func mappingSdkApiErrors_apiErrorWithoutResponse() async throws {
        let error = BitwardenSdk.BitwardenError.EditCipher(.Api(message: "error in reqwest: timed out"))
        await #expect(throws: error) {
            try await ServerError.mappingSdkApiErrors { throw error }
        }
    }

    /// `mappingSdkApiErrors(_:)` rethrows SDK errors that aren't API errors.
    @Test
    func mappingSdkApiErrors_nonApiSdkError() async throws {
        let error = BitwardenSdk.BitwardenError.EditCipher(.Crypto(message: Self.outOfDateMessage))
        await #expect(throws: error) {
            try await ServerError.mappingSdkApiErrors { throw error }
        }
    }

    /// `mappingSdkApiErrors(_:)` rethrows non-SDK errors.
    @Test
    func mappingSdkApiErrors_nonSdkError() async throws {
        await #expect(throws: BitwardenTestError.example) {
            try await ServerError.mappingSdkApiErrors { throw BitwardenTestError.example }
        }
    }
}
