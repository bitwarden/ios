import SwiftUI

/// A view that displays a button for use within a toolbar.
///
struct ToolbarButton: View {
    // MARK: Properties

    /// The action to perform when the user triggers the button.
    var action: () -> Void

    /// The image to display in the button.
    var asset: ImageAsset

    /// The label of the button.
    var label: String

    var body: some View {
        Button(action: action) {
            Image(asset: asset, label: Text(label))
                .resizable()
                .frame(width: 19, height: 19)
        }
        .buttonStyle(.toolbar)
    }

    // MARK: Initialization

    /// Initializes a `ToolbarButton` which styles a button for display within a toolbar.
    ///
    /// - Parameters:
    ///   - asset: The image to display in the button.
    ///   - label: The label of the button.
    ///   - action: The action to perform when the user triggers the button.
    ///
    init(asset: ImageAsset, label: String, action: @escaping () -> Void) {
        self.action = action
        self.asset = asset
        self.label = label
    }
}

// MARK: Previews

#Preview {
    ToolbarButton(asset: Asset.Images.plus, label: Localizations.addItem) {}
}
