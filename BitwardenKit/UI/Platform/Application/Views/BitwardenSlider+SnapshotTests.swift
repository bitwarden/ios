// swiftlint:disable:this file_name
import BitwardenKit
import SnapshotTesting
import XCTest

// MARK: - BitwardenSliderTests

class BitwardenSliderTests: BitwardenTestCase {
    // MARK: Tests

    /// Test a snapshot of the slider with a value of 0.
    func disabletest_snapshot_slider_minValue() {
        let subject = BitwardenSlider(
            value: .constant(0),
            in: 0 ... 50,
            step: 1,
            onEditingChanged: { _ in },
        )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark],
        )
    }

    /// Test a snapshot of the slider with a value of 25.
    func disabletest_snapshot_slider_midValue() {
        let subject = BitwardenSlider(
            value: .constant(25),
            in: 0 ... 50,
            step: 1,
            onEditingChanged: { _ in },
        )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark],
        )
    }

    /// Test a snapshot of the slider with a value of 50.
    func disabletest_snapshot_slider_maxValue() {
        let subject = BitwardenSlider(
            value: .constant(50),
            in: 0 ... 50,
            step: 1,
            onEditingChanged: { _ in },
        )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark],
        )
    }
}
