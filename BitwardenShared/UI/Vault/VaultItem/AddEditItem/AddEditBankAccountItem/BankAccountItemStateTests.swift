import BitwardenSdk
import Foundation
import Testing

@testable import BitwardenShared

struct BankAccountItemStateTests {
    // MARK: Tests

    /// `bankAccountView` maps every populated text field through to the SDK view, mapping a
    /// custom account type to its raw value.
    @Test
    func bankAccountView_populated() {
        var subject = BankAccountItemState()
        subject.bankName = "Bank of America"
        subject.nameOnAccount = "Personal Checking"
        subject.accountType = .custom(.checking)
        subject.accountNumber = "1234567890123456"
        subject.routingNumber = "1234567890"
        subject.branchNumber = "100"
        subject.pin = "1234"
        subject.swiftCode = "123234"
        subject.iban = "23423434543"
        subject.bankContactPhone = "123-456-7890"

        let view = subject.bankAccountView

        #expect(view.bankName == "Bank of America")
        #expect(view.nameOnAccount == "Personal Checking")
        #expect(view.accountType == "checking")
        #expect(view.accountNumber == "1234567890123456")
        #expect(view.routingNumber == "1234567890")
        #expect(view.branchNumber == "100")
        #expect(view.pin == "1234")
        #expect(view.swiftCode == "123234")
        #expect(view.iban == "23423434543")
        #expect(view.bankContactPhone == "123-456-7890")
    }

    /// `bankAccountView` maps every empty field to `nil` via `.nilIfEmpty`, defaulting the account
    /// type to `"checking"`.
    @Test
    func bankAccountView_empty() {
        let subject = BankAccountItemState()

        let view = subject.bankAccountView

        #expect(view.bankName == nil)
        #expect(view.nameOnAccount == nil)
        #expect(view.accountType == "checking")
        #expect(view.accountNumber == nil)
        #expect(view.routingNumber == nil)
        #expect(view.branchNumber == nil)
        #expect(view.pin == nil)
        #expect(view.swiftCode == nil)
        #expect(view.iban == nil)
        #expect(view.bankContactPhone == nil)
    }

    /// `bankAccountView` maps a `.default` account type (only reachable when loading an existing
    /// item with an unrecognized/missing account type) to `nil`.
    @Test
    func bankAccountView_defaultAccountType() {
        var subject = BankAccountItemState()
        subject.accountType = .default

        #expect(subject.bankAccountView.accountType == nil)
    }

    /// `isBankAccountDetailsSectionEmpty` is `false` by default since the account type defaults to
    /// `.custom(.checking)`.
    @Test
    func isBankAccountDetailsSectionEmpty_empty() {
        #expect(!BankAccountItemState().isBankAccountDetailsSectionEmpty)
    }

    /// `isBankAccountDetailsSectionEmpty` is `true` when every field is empty and the account type is
    /// `.default` (only reachable when loading an existing item with an unrecognized/missing account type).
    @Test
    func isBankAccountDetailsSectionEmpty_defaultAccountType() {
        var subject = BankAccountItemState()
        subject.accountType = .default
        #expect(subject.isBankAccountDetailsSectionEmpty)
    }

    /// `isBankAccountDetailsSectionEmpty` is `false` when any string field has a value.
    @Test
    func isBankAccountDetailsSectionEmpty_populatedField() {
        var subject = BankAccountItemState()
        subject.bankName = "Bank of America"
        #expect(!subject.isBankAccountDetailsSectionEmpty)
    }

    /// `isBankAccountDetailsSectionEmpty` is `false` when an account type other than the default is selected
    /// and all other fields are empty.
    @Test
    func isBankAccountDetailsSectionEmpty_accountTypeOnly() {
        var subject = BankAccountItemState()
        subject.accountType = .custom(.savings)
        #expect(!subject.isBankAccountDetailsSectionEmpty)
    }

    /// The account type field is blank until the user has explicitly selected a value.
    @Test
    func accountType_defaultLocalizedName_isBlank() {
        #expect(BankAccountItemState().accountType.localizedName.isEmpty)
    }
}
