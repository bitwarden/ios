// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

class AddEditLoginItemViewTests: BitwardenTestCase {
    // MARK: Snapshots

    /// Test a snapshot of the `AddEditLoginItemView` in its empty state.
    @MainActor
    func test_snapshot_empty() {
        assertSnapshots(
            of: makeView(state: LoginItemState(isTOTPAvailable: false, totpState: .none)),
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 1.5),
            ],
        )
    }

    /// Test a snapshot of the `AddEditLoginItemView` with an authenticator key.
    @MainActor
    func test_snapshot_authKey() {
        // swiftlint:disable:next line_length
        let key = "otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example&algorithm=SHA1&digits=6&period=30"
        assertSnapshots(
            of: makeView(state: LoginItemState(isTOTPAvailable: true, totpState: .init(key))),
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 1.5),
            ],
        )
    }

    // MARK: Private

    /// Returns the view for the given state, wrapped in a scrolling navigation view.
    @MainActor
    private func makeView(state: LoginItemState) -> some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    AddEditLoginItemView(
                        store: Store(processor: StateProcessor(state: state)),
                    )
                }
                .padding(16)
            }
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
            .ignoresSafeArea()
        }
    }
}
