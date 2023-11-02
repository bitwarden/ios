import XCTest

@testable import BitwardenShared

class VaultListGroupTests: BitwardenTestCase {
    // MARK: Tests

    /// `name` returns the display name of the group.
    func test_name() {
        XCTAssertEqual(VaultListGroup.card.name, "Card")
        XCTAssertEqual(VaultListGroup.folder(id: "", name: "Folder 📁").name, "Folder 📁")
        XCTAssertEqual(VaultListGroup.identity.name, "Identity")
        XCTAssertEqual(VaultListGroup.login.name, "Login")
        XCTAssertEqual(VaultListGroup.secureNote.name, "Secure note")
        XCTAssertEqual(VaultListGroup.trash.name, "Trash")
    }
}
