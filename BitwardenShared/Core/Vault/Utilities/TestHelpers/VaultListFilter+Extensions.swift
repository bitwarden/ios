import Combine

@testable import BitwardenShared

extension VaultListFilter {
    /// Returns a publisher that just returns this vault list filter.
    /// - Returns: A publisher with this filter as the value.
    func asPublisher() -> AnyPublisher<VaultListFilter, Error> {
        Just(self)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
