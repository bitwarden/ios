import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class MasterPasswordPolicyOptionsExtensionsTests: BitwardenTestCase {
    // MARK: Tests

    /// `isInEffect` returns `false` if none of the policy options apply.
    func test_isInEffect_false() {
        XCTAssertFalse(
            MasterPasswordPolicyOptions(
                minComplexity: 0,
                minLength: 0,
                requireUpper: false,
                requireLower: false,
                requireNumbers: false,
                requireSpecial: false,
                enforceOnLogin: false
            ).isInEffect
        )
    }

    /// `isInEffect` returns `true` if any of the policy options apply.
    func test_isInEffect_true() {
        XCTAssertTrue(
            MasterPasswordPolicyOptions(
                minComplexity: 0,
                minLength: 12,
                requireUpper: false,
                requireLower: false,
                requireNumbers: false,
                requireSpecial: false,
                enforceOnLogin: false
            ).isInEffect
        )

        XCTAssertTrue(
            MasterPasswordPolicyOptions(
                minComplexity: 0,
                minLength: 0,
                requireUpper: true,
                requireLower: true,
                requireNumbers: true,
                requireSpecial: false,
                enforceOnLogin: false
            ).isInEffect
        )
    }

    /// `policySummary` returns `nil` is the policy isn't in effect.
    func test_policySummary_policyNotInEffect() {
        let policy = MasterPasswordPolicyOptions(
            minComplexity: 0,
            minLength: 0,
            requireUpper: false,
            requireLower: false,
            requireNumbers: false,
            requireSpecial: false,
            enforceOnLogin: false
        )
        XCTAssertNil(policy.policySummary)
    }

    /// `policySummary` returns a summary of the policy if all policy properties are applied.
    func test_policySummary_policyAllInEffect() {
        let policy = MasterPasswordPolicyOptions(
            minComplexity: 4,
            minLength: 16,
            requireUpper: true,
            requireLower: true,
            requireNumbers: true,
            requireSpecial: true,
            enforceOnLogin: true
        )
        try assertInlineSnapshot(
            of: XCTUnwrap(policy.policySummary),
            as: .lines
        ) {
            """
            One or more organization policies require your master password to meet the following requirements:
              • Minimum complexity score of 4
              • Minimum length of 16
              • Contain one or more uppercase characters
              • Contain one or more lowercase characters
              • Contain one or more numbers
              • Contain one or more of the following special characters: !@#$%^&*
            """
        }
    }

    /// `policySummary` returns a summary of the policy if some policy properties are applied.
    func test_policySummary_policyPartialInEffect() {
        let policy = MasterPasswordPolicyOptions(
            minComplexity: 0,
            minLength: 9,
            requireUpper: true,
            requireLower: false,
            requireNumbers: true,
            requireSpecial: true,
            enforceOnLogin: true
        )
        try assertInlineSnapshot(
            of: XCTUnwrap(policy.policySummary),
            as: .lines
        ) {
            """
            One or more organization policies require your master password to meet the following requirements:
              • Minimum length of 9
              • Contain one or more uppercase characters
              • Contain one or more numbers
              • Contain one or more of the following special characters: !@#$%^&*
            """
        }
    }
}
