// swiftlint:disable:this file_name
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenKit

class SettingsPickerFieldTests: BitwardenTestCase {
    // MARK: Properties

    var subject: SettingsPickerField!

    // MARK: Setup & Teardown

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// Test a snapshot of the picker field in light mode without footer.
    func disabletest_snapshot_lightMode_noFooter() {
        subject = SettingsPickerField(
            title: "Title",
            customTimeoutValue: "1:00",
            pickerValue: .constant(3600),
            customTimeoutAccessibilityLabel: "one hour, zero minutes",
        )

        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the picker field in dark mode without footer.
    func disabletest_snapshot_darkMode_noFooter() {
        subject = SettingsPickerField(
            title: "Title",
            customTimeoutValue: "1:00",
            pickerValue: .constant(3600),
            customTimeoutAccessibilityLabel: "one hour, zero minutes",
        )

        assertSnapshot(of: subject, as: .defaultPortraitDark)
    }

    /// Test a snapshot of the picker field with large dynamic type without footer.
    func disabletest_snapshot_largeDynamicType_noFooter() {
        subject = SettingsPickerField(
            title: "Title",
            customTimeoutValue: "1:00",
            pickerValue: .constant(3600),
            customTimeoutAccessibilityLabel: "one hour, zero minutes",
        )

        assertSnapshot(of: subject, as: .defaultPortraitAX5)
    }

    /// Test a snapshot of the picker field in light mode with footer.
    func disabletest_snapshot_lightMode_withFooter() {
        subject = SettingsPickerField(
            title: "Title",
            footer: "Your organization has set the default session timeout to 1 hour.",
            customTimeoutValue: "1:00",
            pickerValue: .constant(3600),
            customTimeoutAccessibilityLabel: "one hour, zero minutes",
        )

        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the picker field in dark mode with footer.
    func disabletest_snapshot_darkMode_withFooter() {
        subject = SettingsPickerField(
            title: "Title",
            footer: "Your organization has set the default session timeout to 1 hour.",
            customTimeoutValue: "1:00",
            pickerValue: .constant(3600),
            customTimeoutAccessibilityLabel: "one hour, zero minutes",
        )

        assertSnapshot(of: subject, as: .defaultPortraitDark)
    }

    /// Test a snapshot of the picker field with large dynamic type with footer.
    func disabletest_snapshot_largeDynamicType_withFooter() {
        subject = SettingsPickerField(
            title: "Title",
            footer: "Your organization has set the default session timeout to 1 hour.",
            customTimeoutValue: "1:00",
            pickerValue: .constant(3600),
            customTimeoutAccessibilityLabel: "one hour, zero minutes",
        )

        assertSnapshot(of: subject, as: .defaultPortraitAX5)
    }

    /// Test a snapshot of the picker field with an empty title.
    func disabletest_snapshot_lightMode_emptyTitle() {
        subject = SettingsPickerField(
            title: "",
            footer: "Your organization has set the default session timeout to 1 hour and 30 minutes.",
            customTimeoutValue: "1:30",
            pickerValue: .constant(5400),
            customTimeoutAccessibilityLabel: "one hour, thirty minutes",
        )

        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
