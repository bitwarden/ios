// MARK: - PremiumCheckoutStatus

/// The status of the premium checkout sync process.
///
enum PremiumCheckoutStatus: Equatable {
    /// The user did not complete the Stripe checkout and returned to the app.
    case canceled

    /// The sync has completed and the user's premium status is confirmed.
    case confirmed

    /// The sync has completed but the user's premium status is not yet active.
    case pending

    /// The sync has started after a premium checkout.
    case syncing
}
