import BitwardenKit
import BitwardenResources

// MARK: - Alert+Account

extension Alert {
    // MARK: Methods

    /// Creates an alert asking if the user wants to use an advanced matching detection option.
    ///
    /// - Parameters:
    ///   - action: The action to perform if the user selects "Yes".
    /// - Returns: An alert prompting the user about advanced matching detection.
    static func confirmRegularExpressionMatchDetectionAlert(
        action: @escaping () async -> Void,
    ) -> Alert {
        Alert(
            title: Localizations.areYouSureYouWantToUseX(Localizations.regEx),
            message: Localizations.regularExpressionIsAnAdvancedOptionWithIncreasedRiskOfExposingCredentials,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in
                    await action()
                },
            ],
        )
    }

    /// Creates an alert asking if the user wants to use an advanced matching detection option.
    ///
    /// - Parameters:
    ///   - action: The action to perform if the user selects "Yes".
    /// - Returns: An alert prompting the user about advanced matching detection.
    static func confirmStartsWithMatchDetectionAlert(
        action: @escaping () async -> Void,
    ) -> Alert {
        Alert(
            title: Localizations.areYouSureYouWantToUseX(Localizations.startsWith),
            message: Localizations.startsWithIsAnAdvancedOptionWithIncreasedRiskOfExposingCredentials,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in
                    await action()
                },
            ],
        )
    }

    /// Creates an alert asking if the user wants to learn more about advanced matching detection options.
    ///
    /// - Parameters:
    ///   - matchingType: The type of matching option to learn more about.
    ///   - action: The action to perform if the user selects "Learn More".
    /// - Returns: An alert prompting the user with additional information about advanced matching detection.
    static func learnMoreAdvancedMatchingDetection(
        _ matchingType: String,
        action: @escaping () async -> Void,
    ) -> Alert {
        Alert(
            title: Localizations.keepYourCredentialsSecure,
            message: Localizations.learnMoreAboutHowToKeepCredentialsSecureWhenUsingX(matchingType),
            alertActions: [
                AlertAction(title: Localizations.close, style: .cancel),
                AlertAction(title: Localizations.learnMore, style: .default) { _ in
                    await action()
                },
            ],
        )
    }
}
