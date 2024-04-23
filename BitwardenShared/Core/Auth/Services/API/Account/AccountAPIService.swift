import CryptoKit
import Foundation
import Networking

// MARK: - AccountAPIService

/// A protocol for an API service used to make account requests.
///
protocol AccountAPIService {
    /// Performs the account revision date request and returns the date of the account's last revision.
    ///
    /// - Returns: The account's last revision date.
    ///
    func accountRevisionDate() async throws -> Date?

    /// Checks if the user's entered password has been found in a data breach.
    ///
    ///  - Parameter password: The user's entered password.
    ///
    ///  - Returns: The number of times the password has been found in a data breach.
    ///
    func checkDataBreaches(password: String) async throws -> Int

    /// Creates an API call for when the user submits an account creation form.
    ///
    /// - Parameter body: The body to be included in the request.
    /// - Returns: Data returned from the `CreateAccountRequest`.
    ///
    func createNewAccount(body: CreateAccountRequestModel) async throws -> CreateAccountResponseModel

    /// Creates an API call for deleting the user's account.
    ///
    /// - Parameter body: The body to be included in the request.
    /// - Returns: An empty response, as the request does not return data.
    ///
    func deleteAccount(body: DeleteAccountRequestModel) async throws -> EmptyResponse

    /// Sends an API call for completing the pre-login step in the auth flow.
    ///
    /// - Parameter email: The email address that the user is attempting to sign in with.
    /// - Returns: Information necessary to complete the next step in the auth flow.
    ///
    func preLogin(email: String) async throws -> PreLoginResponseModel

    /// Requests a one-time password to be sent to the user.
    ///
    func requestOtp() async throws

    /// Requests that the password hint for an account tied to the provided email address be sent to
    /// the user. If this method does not throw an error, than the password hint has been sent to
    /// the user successfully.
    ///
    /// - Parameter email: The email being used to log into the app.
    ///
    func requestPasswordHint(for email: String) async throws

    /// Set the account keys.
    ///
    ///  - Parameter requestModel: The request model containing the keys to set in the account.
    ///
    func setAccountKeys(requestModel: KeysRequestModel) async throws

    /// Performs the API request to set the user's password.
    ///
    /// - Parameter requestModel: The request model containing the details needed to set the user's
    ///     password.
    ///
    func setPassword(_ requestModel: SetPasswordRequestModel) async throws

    /// Performs the API request to update the user's password.
    ///
    /// - Parameter requestModel: The request model used to send the request.
    ///
    func updatePassword(_ requestModel: UpdatePasswordRequestModel) async throws

    /// Performs the API request to update the user's temporary password.
    ///
    /// - Parameter requestModel: The request model used to send the request.
    ///
    func updateTempPassword(_ requestModel: UpdateTempPasswordRequestModel) async throws

    /// Verifies that the entered one-time password matches the one sent to the user.
    ///
    /// - Parameter otp: The user's one-time password to verify.
    ///
    func verifyOtp(_ otp: String) async throws
}

// MARK: - APIService

extension APIService: AccountAPIService {
    func accountRevisionDate() async throws -> Date? {
        try await apiService.send(AccountRevisionDateRequest()).date
    }

    func checkDataBreaches(password: String) async throws -> Int {
        // Generate a SHA1 hash value for the password.
        let fullPasswordHash = Data(password.utf8).generatedHash(using: Insecure.SHA1.self)

        // Get the hash's prefix, which, for security reasons
        // is the only part of the password hash sent in the request.
        let hashPrefix = String(fullPasswordHash.prefix(5))
        let request = HIBPPasswordLeakedRequest(passwordHashPrefix: hashPrefix)
        let response = try await hibpService.send(request)

        // The response contains suffixes beginning with the password's prefix that have been found in a breach.
        // Take the password's suffix, and compare it to the returned suffixes.
        let hashWithoutPrefix = fullPasswordHash.dropFirst(hashPrefix.count).uppercased()

        // If any returned suffixes match the password's suffix, the password has been found in a data breach.
        return response.leakedHashes[hashWithoutPrefix] ?? 0
    }

    func createNewAccount(body: CreateAccountRequestModel) async throws -> CreateAccountResponseModel {
        let request = CreateAccountRequest(body: body)
        return try await identityService.send(request)
    }

    func deleteAccount(body: DeleteAccountRequestModel) async throws -> EmptyResponse {
        let request = DeleteAccountRequest(body: body)
        return try await apiService.send(request)
    }

    func preLogin(email: String) async throws -> PreLoginResponseModel {
        let body = PreLoginRequestModel(email: email)
        let request = PreLoginRequest(body: body)
        let response = try await identityService.send(request)
        return response
    }

    func requestOtp() async throws {
        _ = try await apiService.send(RequestOtpRequest())
    }

    func requestPasswordHint(for email: String) async throws {
        let request = PasswordHintRequest(body: PasswordHintRequestModel(email: email))
        _ = try await apiUnauthenticatedService.send(request)
    }

    func setAccountKeys(requestModel: KeysRequestModel) async throws {
        _ = try await apiService.send(SetAccountKeysRequest(body: requestModel))
    }

    func setPassword(_ requestModel: SetPasswordRequestModel) async throws {
        _ = try await apiService.send(SetPasswordRequest(requestModel: requestModel))
    }

    func updatePassword(_ requestModel: UpdatePasswordRequestModel) async throws {
        _ = try await apiService.send(UpdatePasswordRequest(requestModel: requestModel))
    }

    func updateTempPassword(_ requestModel: UpdateTempPasswordRequestModel) async throws {
        _ = try await apiService.send(UpdateTempPasswordRequest(requestModel: requestModel))
    }

    func verifyOtp(_ otp: String) async throws {
        _ = try await apiService.send(VerifyOtpRequest(requestModel: VerifyOtpRequestModel(otp: otp)))
    }
}
