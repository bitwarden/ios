import Combine

// MARK: - TOTPItemDisplayStateService

/// A protocol for a service that manages how TOTP items are displayed in the item list.
///
protocol TOTPItemDisplayStateService: AnyObject { // sourcery: AutoMockable
    // MARK: Show Next TOTP Code

    /// Get whether to show the next TOTP code preview when the current code is about to expire.
    ///
    /// - Returns: Whether to show the next TOTP code preview.
    ///
    func getShowNextTOTPCode() async -> Bool

    /// Sets whether to show the next TOTP code preview when the current code is about to expire.
    ///
    /// - Parameter value: Whether to show the next TOTP code preview.
    ///
    func setShowNextTOTPCode(_ value: Bool) async

    // MARK: Show Web Icons

    /// Get whether to show website icons.
    ///
    /// - Returns: Whether to show the website icons.
    ///
    func getShowWebIcons() async -> Bool

    /// Set whether to show the website icons.
    ///
    /// - Parameter showWebIcons: Whether to show the website icons.
    ///
    func setShowWebIcons(_ showWebIcons: Bool) async

    /// A publisher for whether or not to show the web icons.
    ///
    /// - Returns: A publisher for whether or not to show the web icons.
    ///
    func showWebIconsPublisher() async -> AnyPublisher<Bool, Never>
}
