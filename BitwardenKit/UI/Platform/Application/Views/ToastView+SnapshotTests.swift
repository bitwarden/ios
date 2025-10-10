// swiftlint:disable:this file_name
import BitwardenKit
import SnapshotTesting
import SwiftUI
import XCTest

final class ToastViewTests: BitwardenTestCase {
    // MARK: Snapshots

    /// The toasts render correctly.
    @MainActor
    func disabletest_snapshot_toasts() {
        let subject = VStack {
            ToastView(toast: .constant(Toast(title: "Toast!")))

            ToastView(toast: .constant(Toast(title: "Toast!", subtitle: "Lorem ipsum dolor sit amet.")))
        }
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
