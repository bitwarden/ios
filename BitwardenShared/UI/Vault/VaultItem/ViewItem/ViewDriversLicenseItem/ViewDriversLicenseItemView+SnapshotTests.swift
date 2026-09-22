// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

class ViewDriversLicenseItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<DriversLicenseItemState, ViewItemAction, Void>!
    var subject: ViewDriversLicenseItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: DriversLicenseItemState())
        subject = ViewDriversLicenseItemView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The empty driver's license view renders correctly.
    @MainActor
    func disabletest_snapshot_empty() {
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait])
    }

    /// The populated driver's license view renders correctly with the license number hidden.
    @MainActor
    func disabletest_snapshot_populated() {
        processor.state = populatedState()
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 1.75)],
        )
    }

    /// The populated driver's license view renders correctly with the license number revealed.
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
            dateOfBirth: Date(year: 1989, month: 8, day: 1),
            expirationDate: Date(year: 2029, month: 8, day: 1),
            firstName: "Bit",
            issueDate: Date(year: 2019, month: 8, day: 1),
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
