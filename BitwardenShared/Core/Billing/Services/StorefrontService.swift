import StoreKit

// MARK: - StorefrontService

/// A protocol for a service used to retrieve App Store storefront information.
///
protocol StorefrontService: AnyObject { // sourcery: AutoMockable
    /// Returns whether the user's App Store storefront is in the United States.
    ///
    /// - Returns: `true` if the storefront country code is "USA", `false` otherwise.
    ///
    func isUSStorefront() async -> Bool
}

// MARK: - DefaultStorefrontService

/// The default implementation of `StorefrontService`.
///
class DefaultStorefrontService: StorefrontService {
    // MARK: Private Properties

    /// Provides the current App Store storefront country code. Injected for testability.
    private let countryCodeProvider: () async -> String?

    // MARK: Initialization

    /// Creates a new `DefaultStorefrontService`.
    ///
    /// - Parameter countryCodeProvider: A closure that returns the current storefront country code.
    ///   Defaults to reading from `Storefront.current`.
    ///
    init(countryCodeProvider: @escaping () async -> String? = { await Storefront.current?.countryCode }) {
        self.countryCodeProvider = countryCodeProvider
    }

    // MARK: Methods

    func isUSStorefront() async -> Bool {
        await countryCodeProvider() == "USA"
    }
}
