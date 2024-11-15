@testable import BitwardenShared

class MockTOTPExpirationManager: TOTPExpirationManager {
    var cleanupCalled = false
    var configuredTOTPRefreshSchedulingItems: [VaultListItem]?
    var onExpiration: (([VaultListItem]) -> Void)?

    func cleanup() {
        cleanupCalled = true
    }

    func configureTOTPRefreshScheduling(for items: [VaultListItem]) {
        configuredTOTPRefreshSchedulingItems = items
    }
}
