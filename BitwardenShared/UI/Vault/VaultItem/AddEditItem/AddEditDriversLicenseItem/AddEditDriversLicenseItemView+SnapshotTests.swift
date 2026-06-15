// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - AddEditDriversLicenseItemViewTests

class AddEditDriversLicenseItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<
        any AddEditDriversLicenseItemState,
        AddEditDriversLicenseItemAction,
        AddEditItemEffect,
    >!
    var subject: AddEditDriversLicenseItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: DriversLicenseItemState() as (any AddEditDriversLicenseItemState))
        subject = AddEditDriversLicenseItemView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The empty add/edit license view renders correctly.
    @MainActor
    func disabletest_snapshot_empty() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 1.75)],
        )
    }

    /// The populated add/edit license view renders correctly, with the license number hidden.
    @MainActor
    func disabletest_snapshot_populated() {
        processor.state = populatedState()
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    /// The populated add/edit license view renders correctly with the license number revealed.
    @MainActor
    func disabletest_snapshot_licenseNumberVisible() {
        var state = populatedState()
        state.isLicenseNumberVisible = true
        processor.state = state
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    // MARK: Helpers

    /// A fully populated driver's license state for snapshots.
    private func populatedState() -> DriversLicenseItemState {
        DriversLicenseItemState(
            dateOfBirth: "1989-08-01",
            expirationDate: "2029-08-01",
            firstName: "Bit",
            issueDate: "2019-08-01",
            issuingAuthority: "DMV",
            issuingCountry: "United States",
            issuingState: "California",
            lastName: "Warden",
            licenseClass: "C",
            licenseNumber: "D1234567",
            middleName: "W",
        )
    }
}
