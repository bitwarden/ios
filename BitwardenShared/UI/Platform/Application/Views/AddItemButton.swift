import SwiftUI

// MARK: - AddItemButton

/// A button styled for the navigation bar that allows the user to add an item.
struct AddItemButton: View {
    /// The action to perform when the user triggers the button.
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(Localizations.addItem)
            } icon: {
                Asset.Images.plus.swiftUIImage
                    .resizable()
                    .frame(width: 16, height: 16)
            }
        }
    }
}
