import Combine

@testable import BitwardenShared

class MockVaultTimeoutService: VaultTimeoutService {
    var isLockedSubject = CurrentValueSubject<Bool, Never>(false)

    func lock() {
        isLockedSubject.send(true)
    }

    func isLockedPublisher() -> AsyncPublisher<AnyPublisher<Bool, Never>> {
        isLockedSubject.eraseToAnyPublisher().values
    }
}
