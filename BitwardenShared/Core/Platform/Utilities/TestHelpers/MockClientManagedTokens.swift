import BitwardenSdk

@testable import BitwardenShared

@MainActor
final class MockClientManagedTokens: ClientManagedTokens {
    var getAccessTokenReturnValue: String?

    func getAccessToken() async -> String? {
        getAccessTokenReturnValue
    }
}
