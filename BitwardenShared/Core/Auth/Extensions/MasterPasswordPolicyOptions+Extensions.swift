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

        let bullet = "\n".appending(String(repeating: " ", count: 2)).appending("\u{2022} ")
        var policySummary = Localizations.masterPasswordPolicyInEffect
        if minComplexity > 0 {
            policySummary.append(bullet)
            policySummary.append(Localizations.policyInEffectMinComplexity(minComplexity))
        }

        if minLength > 0 {
            policySummary.append(bullet)
            policySummary.append(Localizations.policyInEffectMinLength(minLength))
        }

        if requireUpper {
            policySummary.append(bullet)
            policySummary.append(Localizations.policyInEffectUppercase)
        }

        if requireLower {
            policySummary.append(bullet)
            policySummary.append(Localizations.policyInEffectLowercase)
        }

        if requireNumbers {
            policySummary.append(bullet)
            policySummary.append(Localizations.policyInEffectNumbers)
        }

        if requireSpecial {
            policySummary.append(bullet)
            policySummary.append(Localizations.policyInEffectSpecial("!@#$%^&*"))
        }

        return policySummary
    }
}
