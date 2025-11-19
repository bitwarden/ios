/// A protocol to work with processors that have TOTP sections.
@MainActor
protocol HasTOTPCodesSections {
    /// The repository used by the application to manage vault data for the UI layer.
    var vaultRepository: VaultRepository { get }

    /// Refreshes the TOTP Codes from items in sections using the corresponding manager.
    func refreshTOTPCodes(
        for items: [VaultListItem],
        in sections: [VaultListSection],
        using manager: TOTPExpirationManager?,
    ) async throws -> [VaultListSection]
}

/// Extension of the `HasTOTPCodesSections` protocol for some common behavior.
extension HasTOTPCodesSections {
    func refreshTOTPCodes(
        for items: [VaultListItem],
        in sections: [VaultListSection],
        using manager: TOTPExpirationManager?,
    ) async throws -> [VaultListSection] {
        let refreshedItems = try await vaultRepository.refreshTOTPCodes(for: items)
        let updatedSections = sections.updated(with: refreshedItems)
        let allItems = updatedSections.flatMap(\.items)
        manager?.configureTOTPRefreshScheduling(for: allItems)
        return updatedSections
    }
}
