import Networking

// MARK: - VerifyOtpRequestModel

/// API request model for verifying a user's one-time password.
///
struct VerifyOtpRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The user's one-time password to verify.
    let otp: String
}
