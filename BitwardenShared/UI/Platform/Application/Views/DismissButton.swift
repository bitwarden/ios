import SwiftUI

// MARK: - DismissButton

/// A button styled for the navigation bar that allows the user to dismiss a modal.
struct DismissButton: View {
    /// The action to perform when the user triggers the button.
    var action: () -> Void

    var body: some View {
        ToolbarButton(asset: Asset.Images.cancel, label: Localizations.close, action: action)
    }
}
