import BitwardenKit
import Testing

@testable import BitwardenShared

// MARK: - AddEditBankAccountItemStateTests

struct AddEditBankAccountItemStateTests {
    // MARK: Tests

    /// `BankAccountType.defaultValueLocalizedName` is blank so the account type field renders
    /// empty until the user has explicitly made a selection.
    @Test
    func defaultValueLocalizedName_isBlank() {
        #expect(BankAccountType.defaultValueLocalizedName.isEmpty)
    }

    /// `DefaultableType<BankAccountType>.default.localizedName` is blank, matching
    /// `BankAccountType.defaultValueLocalizedName`.
    @Test
    func defaultableType_default_localizedName_isBlank() {
        #expect(DefaultableType<BankAccountType>.default.localizedName.isEmpty)
    }
}
