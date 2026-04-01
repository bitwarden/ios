import Networking

// MARK: - PlanResponseModel

/// API response model for a subscription plan.
///
struct PlanResponseModel: JSONResponse, Equatable, Sendable {
    // MARK: Properties

    /// Whether the plan can be used by a business.
    let canBeUsedByBusiness: Bool

    /// The localization key for the plan description.
    let descriptionLocalizationKey: String

    /// Whether the plan is disabled.
    let disabled: Bool

    /// The sort order for display.
    let displaySortOrder: Int

    /// Whether the plan has two-factor authentication.
    let has2fa: Bool

    /// Whether the plan has API access.
    let hasApi: Bool

    /// Whether the plan has directory integration.
    let hasDirectory: Bool

    /// Whether the plan has event logs.
    let hasEvents: Bool

    /// Whether the plan has groups.
    let hasGroups: Bool

    /// Whether the plan has policies.
    let hasPolicies: Bool

    /// Whether the plan has reset password.
    let hasResetPassword: Bool

    /// Whether the plan supports self-hosting.
    let hasSelfHost: Bool

    /// Whether the plan has SSO.
    let hasSso: Bool

    /// Whether the plan has TOTP.
    let hasTotp: Bool

    /// Whether the plan is billed annually.
    let isAnnual: Bool

    /// The legacy year for this plan.
    let legacyYear: Int?

    /// The name of the plan.
    let name: String

    /// The localization key for the plan name.
    let nameLocalizationKey: String

    /// The Password Manager plan features.
    let passwordManager: PasswordManagerPlanFeaturesResponseModel?

    /// The product tier type.
    let productTier: ProductTierType

    /// The Secrets Manager plan features.
    let secretsManager: SecretsManagerPlanFeaturesResponseModel?

    /// The number of days in the trial period.
    let trialPeriodDays: Int?

    /// The type of plan.
    let type: PlanType

    /// The sort order for upgrade comparison.
    let upgradeSortOrder: Int

    /// Whether users on the plan get premium features.
    let usersGetPremium: Bool

}
