// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

class ViewCardItemViewTests: BitwardenTestCase {
    // MARK: Snapshots

    /// Test preview snapshots of the empty state `ViewCardItemView`.
    ///
    @MainActor
    func test_snapshot_viewCardItemView_empty() {
        assertSnapshots(
            of: makeView(state: CardItemState()),
            as: [
                .defaultPortrait,
            ],
        )
    }

    /// Test preview snapshots of the full visibility state `ViewCardItemView`.
    ///
    @MainActor
    func test_snapshot_viewCardItemView_full() {
        assertSnapshots(
            of: makeView(state: populatedState(isVisible: true)),
            as: [
                .defaultPortrait,
            ],
        )
    }

    /// Test preview snapshots of the full visibility state `ViewCardItemView` in dark mode.
    ///
    @MainActor
    func test_snapshot_viewCardItemView_full_dark() {
        assertSnapshots(
            of: makeView(state: populatedState(isVisible: true)),
            as: [
                .defaultPortraitDark,
            ],
        )
    }

    /// Test preview snapshots of the `ViewCardItemView` with a large font.
    ///
    @MainActor
    func test_snapshot_viewCardItemView_full_largeFont() {
        assertSnapshots(
            of: makeView(state: populatedState(isVisible: true)),
            as: [
                .tallPortraitAX5(heightMultiple: 1.75),
            ],
        )
    }

    /// Test preview snapshots of the `ViewCardItemView` with a hidden number & code.
    ///
    @MainActor
    func test_snapshot_viewCardItemView_hiddenCode() {
        assertSnapshots(
            of: makeView(state: populatedState(isVisible: false)),
            as: [
                .defaultPortrait,
            ],
        )
    }

    /// Test preview snapshots of the `ViewCardItemView` with no expiration data.
    ///
    @MainActor
    func test_snapshot_viewCardItemView_noExpirationState() {
        assertSnapshots(
            of: makeView(state: populatedState(expirationMonth: .default, expirationYear: "")),
            as: [
                .defaultPortrait,
            ],
        )
    }

    /// Test preview snapshots of the `ViewCardItemView` with partial expiration data.
    ///
    @MainActor
    func test_snapshot_viewCardItemView_partialExpirationState() {
        assertSnapshots(
            of: makeView(state: populatedState(expirationMonth: .default)),
            as: [
                .defaultPortrait,
            ],
        )
    }

    // MARK: Private

    /// Returns the view for the given state, wrapped in a scrolling navigation view.
    @MainActor
    private func makeView(state: CardItemState) -> some View {
        NavigationView {
            ScrollView {
                ViewCardItemView(
                    store: Store(
                        processor: StateProcessor(
                            state: state as (any ViewCardItemState),
                        ),
                    ),
                )
                .padding(16)
            }
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
        }
    }

    /// Returns a card state with the card details populated.
    @MainActor
    private func populatedState(
        expirationMonth: DefaultableType<CardComponent.Month> = .custom(.aug),
        expirationYear: String = "1989",
        isVisible: Bool = false,
    ) -> CardItemState {
        var state = CardItemState()
        state.brand = .custom(.visa)
        state.cardNumber = "4400123456789"
        state.cardSecurityCode = "123"
        state.cardholderName = "Bitwarden User"
        state.expirationMonth = expirationMonth
        state.expirationYear = expirationYear
        state.isCodeVisible = isVisible
        state.isNumberVisible = isVisible
        return state
    }
}
