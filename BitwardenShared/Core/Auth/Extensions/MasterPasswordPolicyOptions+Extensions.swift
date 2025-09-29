import BitwardenResources
import BitwardenSdk

extension MasterPasswordPolicyOptions {
    /// Whether the policy has any properties set which would make it apply to the user.
    var isInEffect: Bool {
        minComplexity > 0 ||
            minLength > 0 ||
            requireUpper ||
            requireLower ||
            requireNumbers ||
            requireSpecial
    }

    /// A bulleted list summary of the policy options that apply to the user.
    var policySummary: String? {
        guard isInEffect else { return nil }

        var policies = [String]()
        if minComplexity > 0 {
            policies.append(Localizations.policyInEffectMinComplexity(minComplexity))
        }

        if minLength > 0 {
            policies.append(Localizations.policyInEffectMinLength(minLength))
        }

        if requireUpper {
            policies.append(Localizations.policyInEffectUppercase)
        }

        if requireLower {
            policies.append(Localizations.policyInEffectLowercase)
        }

        if requireNumbers {
            policies.append(Localizations.policyInEffectNumbers)
        }

        if requireSpecial {
            policies.append(Localizations.policyInEffectSpecial("!@#$%^&*"))
        }

        let newLineAndBullet = "\n".appending(String(repeating: " ", count: 2)).appending("\u{2022} ")
        let policySummary = ([Localizations.masterPasswordPolicyInEffect] + policies)
            .joined(separator: newLineAndBullet)

        return policySummary
    }

    /// Initialize a `MasterPasswordPolicyOptions` using API response model for master password policies.
    ///
    /// - Parameter responseModel: API response model for master password policies.
    ///
    init?(responseModel: MasterPasswordPolicyResponseModel?) {
        guard let responseModel else { return nil }
        self.init(
            minComplexity: responseModel.minComplexity ?? 0,
            minLength: responseModel.minLength ?? 0,
            requireUpper: responseModel.requireUpper ?? false,
            requireLower: responseModel.requireLower ?? false,
            requireNumbers: responseModel.requireNumbers ?? false,
            requireSpecial: responseModel.requireSpecial ?? false,
            enforceOnLogin: responseModel.enforceOnLogin ?? false
        )
    }
}
