@testable import AuthenticatorShared

class MockTOTPExpirationManager: TOTPExpirationManager {
    var cleanupCalled = false
    var configuredTOTPRefreshSchedulingItems: [ItemListItem]?
    var onExpiration: (([ItemListItem]) -> Void)?

    func cleanup() {
        cleanupCalled = true
    }

    func configureTOTPRefreshScheduling(for items: [ItemListItem]) {
        configuredTOTPRefreshSchedulingItems = items
    }
}
