// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

class AddEditCardItemViewTests: BitwardenTestCase {
    // MARK: Snapshots

    /// Test snapshots of the `AddEditCardItemView` in its empty state.
    ///
    @MainActor
    func test_snapshot_empty() {
        assertSnapshots(
            of: makeView(state: CardItemState()),
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 1.75),
            ],
        )
    }

    /// Test snapshots of the `AddEditCardItemView` with the number and code hidden.
    ///
    @MainActor
    func test_snapshot_populated_hidden() {
        assertSnapshots(
            of: makeView(state: populatedState(isVisible: false)),
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 1.75),
            ],
        )
    }

    /// Test snapshots of the `AddEditCardItemView` with the number and code visible.
    ///
    @MainActor
    func test_snapshot_populated_visible() {
        assertSnapshots(
            of: makeView(state: populatedState(isVisible: true)),
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 1.75),
            ],
        )
    }

    // MARK: Private

    /// Returns the view for the given state, wrapped in a scrolling navigation view.
    @MainActor
    private func makeView(state: CardItemState) -> some View {
        NavigationView {
            ScrollView {
                AddEditCardItemView(
                    store: Store(
                        processor: StateProcessor(
                            state: state as (any AddEditCardItemState),
                        ),
                    ),
                )
                .padding(16)
            }
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
        }
    }

    /// Returns a card state with all fields populated.
    @MainActor
    private func populatedState(isVisible: Bool) -> CardItemState {
        var state = CardItemState()
        state.brand = .custom(.visa)
        state.cardNumber = "4400123456789"
        state.cardSecurityCode = "123"
        state.cardholderName = "Bitwarden User"
        state.expirationMonth = .custom(.aug)
        state.expirationYear = "1989"
        state.isCodeVisible = isVisible
        state.isNumberVisible = isVisible
        return state
    }
}
