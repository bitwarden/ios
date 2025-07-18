import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

class PasswordStrengthIndicatorTests: BitwardenTestCase {
    // MARK: Tests

    /// `PasswordStrength(_:)` sets the expected color, text and strength percent for a score of 0.
    func test_passwordStrength_0() {
        let view = PasswordStrengthIndicator(
            passwordStrengthScore: 0
        )
        XCTAssertEqual(view.passwordStrength.color.swiftUIColor, SharedAsset.Colors.statusWeak1.swiftUIColor)
        XCTAssertEqual(view.passwordStrength.text, "Weak")
        XCTAssertEqual(view.passwordStrength.strengthPercent, 0.2)
    }

    /// `PasswordStrength(_:)` sets the expected color, text and strength percent for a score of 1.
    func test_passwordStrength_1() {
        let view = PasswordStrengthIndicator(
            passwordStrengthScore: 1
        )
        XCTAssertEqual(view.passwordStrength.color.swiftUIColor, SharedAsset.Colors.statusWeak1.swiftUIColor)
        XCTAssertEqual(view.passwordStrength.text, "Weak")
        XCTAssertEqual(view.passwordStrength.strengthPercent, 0.4)
    }

    /// `PasswordStrength(_:)` sets the expected color, text and strength percent for a score of 2.
    func test_passwordStrength_2() {
        let view = PasswordStrengthIndicator(
            passwordStrengthScore: 2
        )
        XCTAssertEqual(view.passwordStrength.color.swiftUIColor, SharedAsset.Colors.statusWeak2.swiftUIColor)
        XCTAssertEqual(view.passwordStrength.text, "Weak")
        XCTAssertEqual(view.passwordStrength.strengthPercent, 0.6)
    }

    /// `PasswordStrength(_:)` sets the expected color, text and strength percent for a score of 3.
    func test_passwordStrength_3() {
        let view = PasswordStrengthIndicator(
            passwordStrengthScore: 3
        )
        XCTAssertEqual(view.passwordStrength.color.swiftUIColor, SharedAsset.Colors.statusGood.swiftUIColor)
        XCTAssertEqual(view.passwordStrength.text, "Good")
        XCTAssertEqual(view.passwordStrength.strengthPercent, 0.8)
    }

    /// `PasswordStrength(_:)` sets the expected color, text and strength percent for a score of 4.
    func test_passwordStrength_4() {
        let view = PasswordStrengthIndicator(
            passwordStrengthScore: 4
        )
        XCTAssertEqual(view.passwordStrength.color.swiftUIColor, SharedAsset.Colors.statusStrong.swiftUIColor)
        XCTAssertEqual(view.passwordStrength.text, "Strong")
        XCTAssertEqual(view.passwordStrength.strengthPercent, 1)
    }

    /// `PasswordStrength(_:)` sets the expected color, text and strength percent for an invalid score.
    func test_passwordStrength_invalid() {
        let view = PasswordStrengthIndicator(
            passwordStrengthScore: 8
        )
        XCTAssertEqual(view.passwordStrength.color.swiftUIColor, SharedAsset.Colors.statusWeak1.swiftUIColor)
        XCTAssertNil(view.passwordStrength.text)
        XCTAssertEqual(view.passwordStrength.strengthPercent, 0)
    }

    /// `PasswordStrength(_:)` sets the expected color, text and strength percent for a `nil` score.
    func test_passwordStrength_nil() {
        let view = PasswordStrengthIndicator(
            passwordStrengthScore: nil
        )
        XCTAssertEqual(view.passwordStrength.color.swiftUIColor, SharedAsset.Colors.statusWeak1.swiftUIColor)
        XCTAssertNil(view.passwordStrength.text)
        XCTAssertEqual(view.passwordStrength.strengthPercent, 0)
    }

    // MARK: Snapshots

    /// Test a snapshot of the password strength indicator variations.
    func test_snapshot_passwordStrengthIndicator() {
        struct SnapshotView: View {
            var body: some View {
                ScrollView {
                    VStack(spacing: 32) {
                        PasswordStrengthIndicator(
                            passwordStrengthScore: nil
                        )

                        ForEach(UInt8(0) ... UInt8(4), id: \.self) { score in
                            PasswordStrengthIndicator(
                                passwordStrengthScore: score
                            )
                        }
                    }
                    .padding()
                }
            }
        }

        assertSnapshots(of: SnapshotView(), as: [.defaultPortrait, .defaultPortraitDark])
    }
}
