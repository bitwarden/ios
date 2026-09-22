// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - AddEditPassportItemViewTests

class AddEditPassportItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<
        any AddEditPassportItemState,
        AddEditPassportItemAction,
        AddEditItemEffect,
    >!
    var subject: AddEditPassportItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: PassportItemState() as (any AddEditPassportItemState))
        subject = AddEditPassportItemView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The empty add/edit passport view renders correctly.
    @MainActor
    func disabletest_snapshot_empty() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 1.75)],
        )
    }

    /// The populated add/edit passport view renders correctly, with the hidden fields masked.
    @MainActor
    func disabletest_snapshot_populated() {
        processor.state = populatedState()
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    /// The populated add/edit passport view renders correctly with the hidden fields revealed.
    @MainActor
    func disabletest_snapshot_hiddenFieldsVisible() {
        var state = populatedState()
        state.isPassportNumberVisible = true
        state.isNationalIdentificationNumberVisible = true
        processor.state = state
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    // MARK: Helpers

    /// A fully populated passport state used by snapshots.
    private func populatedState() -> PassportItemState {
        PassportItemState(
            birthPlace: "USA",
            dateOfBirth: Date(year: 2025, month: 4, day: 20),
            expirationDate: Date(year: 2026, month: 8, day: 10),
            givenName: "Mitchell",
            issueDate: Date(year: 2021, month: 8, day: 10),
            issuingAuthority: "U.S. Department of State",
            issuingCountry: "United States",
            nationalIdentificationNumber: "123456789",
            nationality: "USA",
            passportNumber: "X12345678",
            passportType: "Regular/Tourist",
            sex: "Male",
            surname: "Johnson",
        )
    }
}
