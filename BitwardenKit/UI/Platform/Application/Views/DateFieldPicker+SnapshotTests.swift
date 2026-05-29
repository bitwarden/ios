// swiftlint:disable:this file_name
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenKit

class DateFieldPickerSnapshotTests: BitwardenTestCase {
    // MARK: Properties

    /// A fixed date used so snapshots are deterministic.
    let date = Date(year: 2023, month: 6, day: 23)

    var subject: DateFieldPicker!

    // MARK: Setup & Teardown

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// Test a snapshot of the collapsed empty field in light mode.
    func disabletest_snapshot_collapsedEmpty_lightMode() {
        subject = DateFieldPicker(title: "Date of birth", date: .constant(nil))

        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the collapsed empty field in dark mode.
    func disabletest_snapshot_collapsedEmpty_darkMode() {
        subject = DateFieldPicker(title: "Date of birth", date: .constant(nil))

        assertSnapshot(of: subject, as: .defaultPortraitDark)
    }

    /// Test a snapshot of the collapsed empty field with large dynamic type.
    func disabletest_snapshot_collapsedEmpty_largeDynamicType() {
        subject = DateFieldPicker(title: "Date of birth", date: .constant(nil))

        assertSnapshot(of: subject, as: .defaultPortraitAX5)
    }

    /// Test a snapshot of a collapsed field with a selected date in light mode.
    func disabletest_snapshot_collapsedSelected_lightMode() {
        subject = DateFieldPicker(title: "Expiration date", date: .constant(date))

        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of a collapsed field with a selected date in dark mode.
    func disabletest_snapshot_collapsedSelected_darkMode() {
        subject = DateFieldPicker(title: "Expiration date", date: .constant(date))

        assertSnapshot(of: subject, as: .defaultPortraitDark)
    }

    /// Test a snapshot of a collapsed field with a footer in light mode.
    func disabletest_snapshot_withFooter_lightMode() {
        subject = DateFieldPicker(
            title: "Expiration date",
            date: .constant(date),
            footer: "The date this document expires.",
        )

        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
