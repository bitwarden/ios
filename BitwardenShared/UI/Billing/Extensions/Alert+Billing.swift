import BitwardenKit
import BitwardenResources

// MARK: - Alert+Billing

extension Alert {
    // MARK: Static Methods

    /// An alert shown when the user returns from Stripe without completing payment.
    ///
    /// - Parameter goBackHandler: A closure called when the user taps "Go back".
    /// - Returns: An `Alert` with "Close" and "Go back" actions.
    ///
    static func paymentNotReceivedYet(
        goBackHandler: @escaping () async -> Void,
    ) -> Alert {
        Alert(
            title: Localizations.paymentNotReceivedYet,
            message: Localizations.returnToStripeInYourBrowserToFinishYourUpgradeDescriptionLong,
            alertActions: [
                AlertAction(
                    title: Localizations.close,
                    style: .cancel,
                ),
                AlertAction(
                    title: Localizations.goBack,
                    style: .default,
                    handler: { _, _ in
                        await goBackHandler()
                    },
                ),
            ],
        )
    }

    /// An alert shown when the Stripe checkout session fails to load.
    ///
    /// - Parameter tryAgainHandler: A closure called when the user taps "Try again".
    /// - Returns: An `Alert` with "Close" and "Try again" actions.
    ///
    static func secureCheckoutDidntLoad(
        tryAgainHandler: @escaping () async -> Void,
    ) -> Alert {
        Alert(
            title: Localizations.secureCheckoutDidntLoad,
            message: Localizations.weHadTroubleOpeningThePaymentPageDescriptionLong,
            alertActions: [
                AlertAction(
                    title: Localizations.close,
                    style: .cancel,
                ),
                AlertAction(
                    title: Localizations.tryAgain,
                    style: .default,
                    handler: { _, _ in
                        await tryAgainHandler()
                    },
                ),
            ],
        )
    }

    /// An alert shown when a premium upgrade is still being processed.
    ///
    /// - Parameter syncNowHandler: A closure called when the user taps "Sync now".
    /// - Returns: An `Alert` with "Continue" and "Sync now" actions.
    ///
    static func upgradePending(
        syncNowHandler: @escaping () async -> Void,
    ) -> Alert {
        Alert(
            title: Localizations.upgradePending,
            message: Localizations.yourUpgradeIsBeingProcessedDescriptionLong,
            alertActions: [
                AlertAction(
                    title: Localizations.continue,
                    style: .cancel,
                ),
                AlertAction(
                    title: Localizations.syncNow,
                    style: .default,
                    handler: { _, _ in
                        await syncNowHandler()
                    },
                ),
            ],
        )
    }
}
