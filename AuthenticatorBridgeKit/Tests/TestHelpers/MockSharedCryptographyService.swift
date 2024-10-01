import CryptoKit
import Foundation

@testable import AuthenticatorBridgeKit

class MockSharedCryptographyService: SharedCryptographyService {
    var decryptCalled = false
    var encryptCalled = false

    func decryptAuthenticatorItemDatas(
        _ items: [AuthenticatorBridgeKit.AuthenticatorBridgeItemData]
    ) async throws -> [AuthenticatorBridgeKit.AuthenticatorBridgeItemDataView] {
        decryptCalled = true

        return items.compactMap { item in
            guard let model = item.model else { return nil }

            return AuthenticatorBridgeItemDataView(
                favorite: model.favorite,
                id: model.id,
                name: model.name,
                totpKey: model.totpKey,
                username: model.username
            )
        }
    }

    func decryptAuthenticatorItems(
        _ items: [AuthenticatorBridgeItemDataModel]
    ) async throws -> [AuthenticatorBridgeItemDataView] {
        decryptCalled = true
        return items.map { model in
            AuthenticatorBridgeItemDataView(
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
                favorite: view.favorite,
                id: view.id,
                name: view.name,
                totpKey: view.totpKey,
                username: view.username
            )
        }
    }
}
