// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - AddEditBankAccountItemViewTests

class AddEditBankAccountItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<
        any AddEditBankAccountItemState,
        AddEditBankAccountItemAction,
        AddEditItemEffect,
    >!
    var subject: AddEditBankAccountItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: BankAccountItemState() as (any AddEditBankAccountItemState))
        subject = AddEditBankAccountItemView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The empty add/edit bank account view renders correctly.
    @MainActor
    func disabletest_snapshot_empty() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 1.75)],
        )
    }

    /// The populated add/edit bank account view renders correctly, with the reveal fields hidden.
    @MainActor
    func disabletest_snapshot_populated() {
        processor.state = populatedState()
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    /// The populated add/edit bank account view renders correctly with the account number, PIN, and
    /// IBAN revealed.
    @MainActor
    func disabletest_snapshot_revealFieldsVisible() {
        var state = populatedState()
        state.isAccountNumberVisible = true
        state.isPinVisible = true
        state.isIbanVisible = true
        processor.state = state
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    // MARK: Helpers

    /// A fully populated bank account state for snapshots.
    private func populatedState() -> BankAccountItemState {
        var state = BankAccountItemState()
        state.bankName = "Bank of America"
        state.nameOnAccount = "Personal Checking"
        state.accountType = .custom(.checking)
        state.accountNumber = "1234567890123456"
        state.routingNumber = "1234567890"
        state.branchNumber = "100"
        state.pin = "1234"
        state.swiftCode = "123234"
        state.iban = "23423434543"
        state.bankContactPhone = "123-456-7890"
        return state
    }
}
