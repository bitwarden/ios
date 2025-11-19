import CryptoKit
import Foundation

@testable import AuthenticatorBridgeKit

class MockSharedCryptographyService: SharedCryptographyService {
    var decryptCalled = false
    var encryptCalled = false
    var errorToThrow: Error?

    func decryptAuthenticatorItems(
        _ items: [AuthenticatorBridgeItemDataModel],
    ) async throws -> [AuthenticatorBridgeItemDataView] {
        if let errorToThrow {
            throw errorToThrow
        }
        decryptCalled = true
        return items.map { model in
            AuthenticatorBridgeItemDataView(
                accountDomain: model.accountDomain,
                accountEmail: model.accountEmail,
                favorite: model.favorite,
                id: model.id,
                name: model.name,
                totpKey: model.totpKey,
                username: model.username,
            )
        }
    }

    func encryptAuthenticatorItems(
        _ items: [AuthenticatorBridgeItemDataView],
    ) async throws -> [AuthenticatorBridgeItemDataModel] {
        if let errorToThrow {
            throw errorToThrow
        }
        encryptCalled = true
        return items.map { view in
            AuthenticatorBridgeItemDataModel(
                accountDomain: view.accountDomain,
                accountEmail: view.accountEmail,
                favorite: view.favorite,
                id: view.id,
                name: view.name,
                totpKey: view.totpKey,
                username: view.username,
            )
        }
    }
}
