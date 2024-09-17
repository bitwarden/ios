import CryptoKit
import Foundation

@testable import AuthenticatorBridgeKit

class MockSharedCryptographyService: SharedCryptographyService {
    var decryptCalled = false
    var encryptCalled = false

    func decryptAuthenticatorItems(
        _ items: [AuthenticatorBridgeItemDataModel]
    ) async throws -> [AuthenticatorBridgeItemDataModel] {
        decryptCalled = true
        return items
    }

    func encryptAuthenticatorItems(
        _ items: [AuthenticatorBridgeItemDataModel]
    ) async throws -> [AuthenticatorBridgeItemDataModel] {
        encryptCalled = true
        return items
    }
}
