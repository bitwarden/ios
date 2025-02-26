import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

final class ToastViewTests: BitwardenTestCase {
    // MARK: Snapshots

    /// The toasts render correctly.
    @MainActor
    func test_snapshot_toasts() {
        let subject = VStack {
            ToastView(toast: .constant(Toast(title: "Toast!")))

            ToastView(toast: .constant(Toast(title: "Toast!", subtitle: "Lorem ipsum dolor sit amet.")))
        }
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
}
