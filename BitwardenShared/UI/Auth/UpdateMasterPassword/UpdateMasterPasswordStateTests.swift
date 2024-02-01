import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - UpdateMasterPasswordStateTests

class UpdateMasterPasswordStateTests: BitwardenTestCase {
    // MARK: Tests

    func test_policySummaryEmpty_policyNil() {
        let subject = UpdateMasterPasswordState()
        XCTAssertEqual(subject.policySummary, Localizations.masterPasswordPolicyInEffect)
    }

    func test_policySummaryEmpty_policyNotInEffect() {
        let policy = MasterPasswordPolicyOptions(
            minComplexity: 0,
            minLength: 0,
            requireUpper: false,
            requireLower: false,
            requireNumbers: false,
            requireSpecial: false,
            enforceOnLogin: false
        )
        let subject = UpdateMasterPasswordState(masterPasswordPolicy: policy)
        XCTAssertEqual(subject.policySummary, Localizations.masterPasswordPolicyInEffect)
    }

    func test_policySummaryEmpty_policyAllInEffect() {
        let policy = MasterPasswordPolicyOptions(
            minComplexity: 4,
            minLength: 16,
            requireUpper: true,
            requireLower: true,
            requireNumbers: true,
            requireSpecial: true,
            enforceOnLogin: true
        )
        let subject = UpdateMasterPasswordState(masterPasswordPolicy: policy)
        assertInlineSnapshot(
            of: subject.policySummary,
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

    func test_policySummaryEmpty_policyPartialInEffect() {
        let policy = MasterPasswordPolicyOptions(
            minComplexity: 0,
            minLength: 9,
            requireUpper: true,
            requireLower: false,
            requireNumbers: true,
            requireSpecial: true,
            enforceOnLogin: true
        )
        let subject = UpdateMasterPasswordState(masterPasswordPolicy: policy)
        assertInlineSnapshot(
            of: subject.policySummary,
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
