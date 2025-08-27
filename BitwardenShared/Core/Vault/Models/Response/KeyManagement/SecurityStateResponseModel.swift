import BitwardenSdk

/// API response model for the security state.
///
struct SecurityStateResponseModel: Codable, Equatable {
    /// The security state.
    let securityState: SignedSecurityState?
}
