// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

class ViewBankAccountItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<BankAccountItemState, ViewItemAction, Void>!
    var subject: ViewBankAccountItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: BankAccountItemState())
        subject = ViewBankAccountItemView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The empty bank account view renders correctly.
    @MainActor
    func disabletest_snapshot_empty() {
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait])
    }

    /// The populated bank account view renders correctly with the sensitive fields hidden.
    @MainActor
    func disabletest_snapshot_populated() {
        processor.state = populatedState()
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 1.75)],
        )
    }

    /// The populated bank account view renders correctly with the sensitive fields revealed.
    @MainActor
    func disabletest_snapshot_sensitiveFieldsVisible() {
        var state = populatedState()
        state.isAccountNumberVisible = true
        state.isIbanVisible = true
        state.isPinVisible = true
        processor.state = state
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    // MARK: Helpers

    /// A fully populated bank account state for snapshots.
    private func populatedState() -> BankAccountItemState {
        var state = BankAccountItemState()
        state.accountNumber = "1234567890123456"
        state.accountType = .custom(.checking)
        state.bankContactPhone = "123-456-7890"
        state.bankName = "Bank of America"
        state.branchNumber = "100"
        state.iban = "GB33BUKB20201555555555"
        state.nameOnAccount = "Personal Checking"
        state.pin = "1234"
        state.routingNumber = "1234567890"
        state.swiftCode = "BOFAUS3N"
        return state
    }
}
