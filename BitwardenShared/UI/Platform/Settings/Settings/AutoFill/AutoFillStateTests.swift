import Testing

@testable import BitwardenShared

// MARK: - AutoFillStateTests

struct AutoFillStateTests {
    // MARK: Tests

    /// `shouldShowAutofillActionCard` is `true` when the user's autofill setup is incomplete and
    /// the autofill off action card is disabled.
    @Test
    func shouldShowAutofillActionCard_setupIncomplete() {
        var subject = AutoFillState()
        subject.badgeState = .fixture(autofillSetupProgress: .setUpLater)
        #expect(subject.shouldShowAutofillActionCard)
    }

    /// `shouldShowAutofillActionCard` is `false` when the user's autofill setup is complete.
    @Test
    func shouldShowAutofillActionCard_setupComplete() {
        var subject = AutoFillState()
        subject.badgeState = .fixture(autofillSetupProgress: .complete)
        #expect(!subject.shouldShowAutofillActionCard)
    }

    /// `shouldShowAutofillActionCard` is `false` when the autofill off action card is enabled,
    /// regardless of the user's autofill setup progress.
    @Test
    func shouldShowAutofillActionCard_autofillOffActionCardEnabled() {
        var subject = AutoFillState()
        subject.badgeState = .fixture(autofillSetupProgress: .setUpLater)
        subject.isAutofillOffActionCardEnabled = true
        #expect(!subject.shouldShowAutofillActionCard)
    }

    /// `shouldShowAutofillOffActionCard` is `true` only when the feature flag is enabled and
    /// autofill is known to be off.
    @Test(arguments: [false, true], [Bool?.none, false, true])
    func shouldShowAutofillOffActionCard(isFlagEnabled: Bool, isAutofillEnabled: Bool?) {
        var subject = AutoFillState()
        subject.isAutofillEnabled = isAutofillEnabled
        subject.isAutofillOffActionCardEnabled = isFlagEnabled
        #expect(subject.shouldShowAutofillOffActionCard == (isFlagEnabled && isAutofillEnabled == false))
    }
}
