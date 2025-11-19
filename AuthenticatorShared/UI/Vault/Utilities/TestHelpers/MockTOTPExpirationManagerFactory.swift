@testable import AuthenticatorShared
import BitwardenKitMocks
import Combine

class MockTOTPExpirationManagerFactory: TOTPExpirationManagerFactory {
    var cancellables: Set<AnyCancellable> = []
    var createTimesCalled: Int = 0
    var createResults: [TOTPExpirationManager] = []
    var onExpirationClosures: [(([ItemListItem]) -> Void)?] = []

    func create(
        itemPublisher: AnyPublisher<[ItemListSection]?, Never>,
        onExpiration: (([ItemListItem]) -> Void)?,
    ) -> TOTPExpirationManager {
        defer { createTimesCalled += 1 }
        onExpirationClosures.append(onExpiration)

        let manager = createResults[createTimesCalled]
        itemPublisher
            .sink { [manager] sections in
                let items = sections?.flatMap(\.items) ?? []
                manager.configureTOTPRefreshScheduling(for: items)
            }
            .store(in: &cancellables)

        return manager
    }
}
