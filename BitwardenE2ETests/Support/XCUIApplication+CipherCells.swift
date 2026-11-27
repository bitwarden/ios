import XCTest

extension XCUIApplication {
    /// The list row of the item with the given name. Rows are the same in the app's vault list and
    /// in the AutoFill extension's item list.
    ///
    func cipherCell(named name: String) -> XCUIElement {
        cipherCell(labelIdentifier: "CipherNameLabel", label: name)
    }

    /// The list row of the item with the given subtitle, which for a login is its username.
    ///
    func cipherCell(subtitled subtitle: String) -> XCUIElement {
        cipherCell(labelIdentifier: "CipherSubTitleLabel", label: subtitle)
    }

    private func cipherCell(labelIdentifier: String, label: String) -> XCUIElement {
        buttons
            .matching(identifier: "CipherCell")
            .containing(NSPredicate(format: "identifier == %@ AND label == %@", labelIdentifier, label))
            .firstMatch
    }
}
