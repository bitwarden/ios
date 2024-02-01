import BitwardenSdk

// MARK: - UpdateMasterPasswordState

/// An object that defines the current state of a `UpdateMasterPasswordView`.
///
struct UpdateMasterPasswordState: Equatable {
    // MARK: Properties

    /// The current master password provided by the user.
    var currentMasterPassword: String = ""

    /// A flag indicating if the current master password should be revealed or not.
    var isCurrentMasterPasswordRevealed: Bool = false

    /// A flag indicating if the new master password should be revealed or not.
    var isMasterPasswordRevealed: Bool = false

    /// A flag indicating if the retype of new master password should be revealed or not.
    var isMasterPasswordRetypeRevealed: Bool = false

    /// The new master password provided by the user.
    var masterPassword: String = ""

    /// The new master password hint provided by the user.
    var masterPasswordHint: String = ""

    var masterPasswordPolicy: MasterPasswordPolicyOptions?

    /// The retype of new master password provided by the user.
    var masterPasswordRetype: String = ""

    var policySummary: String {
        guard let masterPasswordPolicy, masterPasswordPolicy.inEffect() else {
            return Localizations.masterPasswordPolicyInEffect
        }
        let bullet = "\n".appending(String(repeating: " ", count: 2)).appending("\u{2022} ")
        var policySummary = Localizations.masterPasswordPolicyInEffect
        if masterPasswordPolicy.minComplexity > 0 {
            policySummary.append(bullet)
            policySummary.append(Localizations.policyInEffectMinComplexity(masterPasswordPolicy.minComplexity))
        }

        if masterPasswordPolicy.minLength > 0 {
            policySummary.append(bullet)
            policySummary.append(Localizations.policyInEffectMinLength(masterPasswordPolicy.minLength))
        }

        if masterPasswordPolicy.requireUpper {
            policySummary.append(bullet)
            policySummary.append(Localizations.policyInEffectUppercase)
        }

        if masterPasswordPolicy.requireLower {
            policySummary.append(bullet)
            policySummary.append(Localizations.policyInEffectLowercase)
        }

        if masterPasswordPolicy.requireNumbers {
            policySummary.append(bullet)
            policySummary.append(Localizations.policyInEffectNumbers)
        }

        if masterPasswordPolicy.requireSpecial {
            policySummary.append(bullet)
            policySummary.append(Localizations.policyInEffectSpecial("!@#$%^&*"))
        }
        print(policySummary)
        return policySummary
    }
}

extension MasterPasswordPolicyOptions {
    func inEffect() -> Bool {
        minComplexity > 0 ||
            minLength > 0 ||
            requireUpper ||
            requireLower ||
            requireNumbers ||
            requireSpecial
    }
}
