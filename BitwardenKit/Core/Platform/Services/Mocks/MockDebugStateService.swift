import BitwardenKit

public final class MockDebugStateService: DebugStateService {
    public var clearMasterPasswordUnlockForActiveAccountCalled = false // swiftlint:disable:this identifier_name
    // swiftlint:disable:next identifier_name
    public var clearMasterPasswordUnlockForActiveAccountResult: Result<Void, Error> = .success(())

    public init() {}

    public func clearMasterPasswordUnlockForActiveAccount() async throws {
        clearMasterPasswordUnlockForActiveAccountCalled = true
        try clearMasterPasswordUnlockForActiveAccountResult.get()
    }
}
