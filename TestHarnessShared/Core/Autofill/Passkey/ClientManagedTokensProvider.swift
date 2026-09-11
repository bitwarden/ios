import BitwardenSdk

// MARK: - ClientManagedTokensProvider

/// A `ClientManagedTokens` implementation for the passkey scenarios, which never
/// make network requests and so never have an access token to provide.
///
final class ClientManagedTokensProvider: ClientManagedTokens {
    func getAccessToken() async -> String? {
        nil
    }
}
