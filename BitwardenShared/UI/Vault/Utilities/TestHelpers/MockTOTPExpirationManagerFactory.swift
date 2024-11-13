@testable import BitwardenShared

class MockTOTPExpirationManagerFactory: TOTPExpirationManagerFactory {
    var createTimesCalled: Int = 0
    var createResults: [TOTPExpirationManager] = []
    var onExpirationClosures: [(([VaultListItem]) -> Void)?] = []

    func create(onExpiration: (([VaultListItem]) -> Void)?) -> TOTPExpirationManager {
        defer { createTimesCalled += 1 }
        onExpirationClosures.append(onExpiration)
        return createResults[createTimesCalled]
    }
}
