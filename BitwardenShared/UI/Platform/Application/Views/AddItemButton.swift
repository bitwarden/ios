import SwiftUI

// MARK: - AddItemButton

/// A button styled for the navigation bar that allows the user to add an item.
struct AddItemButton: View {
    /// The action to perform when the user triggers the button.
    var action: () -> Void

    var body: some View {
        ToolbarButton(asset: Asset.Images.plus, label: Localizations.addItem, action: action)
    }
}
