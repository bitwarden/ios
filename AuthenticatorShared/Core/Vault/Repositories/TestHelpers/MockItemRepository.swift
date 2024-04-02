import BitwardenSdk
import Combine
import Foundation

@testable import AuthenticatorShared

class MockItemRepository: ItemRepository {
    var vaultListSubject = CurrentValueSubject<[VaultListItem], Never>([])

    func addItem(_ item: BitwardenSdk.CipherView) async throws {

    }
    
    func deleteItem(_ id: String) {

    }
    
    func fetchItem(withId id: String) async throws -> BitwardenSdk.CipherView? {
        nil
    }
    
    func refreshTOTPCode(for key: TOTPKeyModel) async throws -> LoginTOTPState {
        .none
    }
    
    func refreshTOTPCodes(for items: [VaultListItem]) async throws -> [VaultListItem] {
        []
    }
    
    func updateItem(_ item: BitwardenSdk.CipherView) async throws {

    }
    
    func vaultListPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Never>> {
        vaultListSubject.eraseToAnyPublisher().values
    }
    

}
