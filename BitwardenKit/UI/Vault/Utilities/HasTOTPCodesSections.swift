import Foundation

/// A protocol to work with processors that have TOTP sections.
@MainActor
public protocol HasTOTPCodesSections {
    // MARK: Types

    /// The type of item contained in each section.
    associatedtype Item
    /// The type of section contained in the list.
    associatedtype Section: TOTPUpdatableSection where Section.Item == Item
    /// The type of repository that has item to refresh.
    associatedtype Repository: TOTPRefreshingRepository where Repository.Item == Item

    // MARK: Methods

    /// The repository used to refresh TOTP codes.
    var repository: Repository { get }

    /// Refresh the TOTP codes for items in the given sections.
    func refreshTOTPCodes(for items: [Item], in sections: [Section]) async throws -> [Section]
}

public extension HasTOTPCodesSections {
    /// Refresh the TOTP codes for items in the given sections.
    func refreshTOTPCodes(for items: [Item], in sections: [Section]) async throws -> [Section] {
        let refreshed = try await repository.refreshTotpCodes(for: items)
        return Section.updated(with: refreshed, from: sections)
    }
}

/// The repository used to refresh TOTP codes.
///
public protocol TOTPRefreshingRepository {
    // MARK: Types

    /// The type of item contained in each section.
    associatedtype Item

    // MARK: Methods

    /// Refresh TOTP codes for the given items.
    func refreshTotpCodes(for items: [Item]) async throws -> [Item]
}

/// A section type that supports updating its items with refreshed values.
///
public protocol TOTPUpdatableSection {
    // MARK: Types

    /// The type of item contained in each section.
    associatedtype Item
    /// The list of item contained in the section.
    var items: [Item] { get }

    // MARK: Methods

    /// Update the array of sections with a batch of refreshed items.
    ///
    /// - Parameters:
    ///   - items: An array of updated items that should replace matching items in the current sections.
    ///   - sections: The array of sections to update.
    /// - Returns: A new array of sections with the updated items applied.
    static func updated(with items: [Item], from sections: [Self]) -> [Self]
}
