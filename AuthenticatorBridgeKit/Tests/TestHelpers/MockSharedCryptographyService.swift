import CryptoKit
import Foundation

@testable import AuthenticatorBridgeKit

class MockSharedCryptographyService: SharedCryptographyService {
    var decryptCalled = false
    var encryptCalled = false

    func decryptAuthenticatorItems(
        _ items: [AuthenticatorBridgeItemDataModel]
    ) async throws -> [AuthenticatorBridgeItemDataView] {
        decryptCalled = true
        return items.map { model in
            AuthenticatorBridgeItemDataView(
                bitwardenAccountDomain: model.bitwardenAccountDomain,
                bitwardenAccountEmail: model.bitwardenAccountEmail,
                favorite: model.favorite,
                id: model.id,
                name: model.name,
                totpKey: model.totpKey,
                username: model.username
            )
        }
    }

    func encryptAuthenticatorItems(
        _ items: [AuthenticatorBridgeItemDataView]
    ) async throws -> [AuthenticatorBridgeItemDataModel] {
        encryptCalled = true
        return items.map { view in
            AuthenticatorBridgeItemDataModel(
                bitwardenAccountDomain: view.bitwardenAccountDomain,
                bitwardenAccountEmail: view.bitwardenAccountEmail,
                favorite: view.favorite,
                id: view.id,
                name: view.name,
                totpKey: view.totpKey,
                username: view.username
            )
        }
    }
}
