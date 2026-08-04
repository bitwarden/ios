// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

class ViewPassportItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<PassportItemState, ViewItemAction, Void>!
    var subject: ViewPassportItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: PassportItemState())
        subject = ViewPassportItemView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The empty passport view renders correctly.
    @MainActor
    func disabletest_snapshot_empty() {
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait])
    }

    /// The populated passport view renders correctly with the sensitive fields hidden.
    @MainActor
    func disabletest_snapshot_populated() {
        processor.state = populatedState()
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 1.75)],
        )
    }

    /// The populated passport view renders correctly with the sensitive fields revealed.
    @MainActor
    func disabletest_snapshot_sensitiveFieldsVisible() {
        var state = populatedState()
        state.isNationalIdentificationNumberVisible = true
        state.isPassportNumberVisible = true
        processor.state = state
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    // MARK: Helpers

    /// A fully populated passport state for snapshots.
    private func populatedState() -> PassportItemState {
        PassportItemState(
            birthPlace: "San Francisco, USA",
            dateOfBirth: "1989-08-01",
            expirationDate: "2029-08-01",
            givenName: "Bit",
            issueDate: "2019-08-01",
            issuingAuthority: "U.S. Department of State",
            issuingCountry: "United States",
            nationalIdentificationNumber: "123456789",
            nationality: "USA",
            passportNumber: "X12345678",
            passportType: "Regular/Tourist",
            sex: "Male",
            surname: "Warden",
        )
    }
}
