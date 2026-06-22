import BitwardenKit

public final class MockDebugStateService: DebugStateService {
    public init() {}
    public func clearMasterPasswordUnlockForActiveAccount() async throws {}
}
