import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

final class EmptyContentViewTests: BitwardenTestCase {
    // MARK: Snapshots

    /// Test a snapshot of the empty content view.
    func test_snapshot_emptyContentView() {
        struct SnapshotView: View {
            var body: some View {
                EmptyContentView(
                    image: Asset.Images.items.swiftUIImage,
                    text: Localizations.thereAreNoItemsInYourVaultThatMatchX("Bitwarden")
                ) {
                    Button {} label: {
                        Label { Text(Localizations.addItem) } icon: {
                            Asset.Images.plus.swiftUIImage
                                .imageStyle(.accessoryIcon(
                                    color: Asset.Colors.buttonFilledForeground.swiftUIColor,
                                    scaleWithFont: true
                                ))
                        }
                    }
                }
            }
        }

        assertSnapshots(of: SnapshotView(), as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
