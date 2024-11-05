import AuthenticatorBridgeKit
@testable import BitwardenShared

class MockAuthenticatorSyncService: AuthenticatorSyncService {
    var tempItem: AuthenticatorBridgeItemDataView?

    func getTemporaryTotpItem() async -> AuthenticatorBridgeItemDataView? {
        tempItem
    }

    func start() {}
}
