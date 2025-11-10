import BitwardenKit
import TestHelpers

public class MockActiveAccountStateProvider: ActiveAccountStateProvider {
    public var activeAccountId: String?

    public init() {}

    public func getActiveAccountId() async throws -> String {
        guard let activeAccountId else { throw ActiveAccountStateProviderError.noActiveAccount }
        return activeAccountId
    }
}
