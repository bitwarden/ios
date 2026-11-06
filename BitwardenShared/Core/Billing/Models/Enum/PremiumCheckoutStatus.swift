// MARK: - PremiumCheckoutStatus

/// The status of the Premium checkout sync process.
///
enum PremiumCheckoutStatus: Equatable {
    /// The user did not complete the Stripe checkout and returned to the app.
    case canceled

    /// The sync has completed and the user's Premium status is confirmed.
    case confirmed

    /// The sync has completed but the user's Premium status is not yet active.
    case pending

    /// The sync has started after a Premium checkout.
    case syncing
}
