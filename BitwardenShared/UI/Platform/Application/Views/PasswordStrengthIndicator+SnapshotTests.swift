// swiftlint:disable:this file_name
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

class PasswordStrengthIndicatorTests: BitwardenTestCase {
    // MARK: Snapshots

    /// Test a snapshot of the password strength indicator variations.
    func disabletest_snapshot_passwordStrengthIndicator() {
        struct SnapshotView: View {
            var body: some View {
                ScrollView {
                    VStack(spacing: 32) {
                        PasswordStrengthIndicator(
                            passwordStrengthScore: nil,
                        )

                        ForEach(UInt8(0) ... UInt8(4), id: \.self) { score in
                            PasswordStrengthIndicator(
                                passwordStrengthScore: score,
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
