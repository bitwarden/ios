import BitwardenKit
import BitwardenSdk
import Combine

// MARK: - VaultListDirectorStrategy

/// A protocol for a strategy for a vault list directo that determines how the vault list sections are built.
protocol VaultListDirectorStrategy {
    /// Builds the vault list sections.
    /// - Parameters:
    ///   - filter: Filter to be used to build the sections.
    /// - Returns: Sections to be displayed to the user.
    func build(
        filter: VaultListFilter
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListSection], Error>>
}
