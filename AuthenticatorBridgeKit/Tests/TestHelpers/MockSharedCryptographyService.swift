import CryptoKit
import Foundation

@testable import AuthenticatorBridgeKit

class MockSharedCryptographyService: SharedCryptographyService {
    func decryptAuthenticatorItems(
        _ items: [AuthenticatorBridgeItemDataModel]
    ) async throws -> [AuthenticatorBridgeItemDataModel] {
        items
    }

    func encryptAuthenticatorItems(
        _ items: [AuthenticatorBridgeItemDataModel]
    ) async throws -> [AuthenticatorBridgeItemDataModel] {
        items
    }
}
