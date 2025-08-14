import BitwardenResources
import SwiftUI

/// A view that displays a button for use as an accessory to a field.
///
struct AccessoryButton: View {
    // MARK: Types

    /// A type that wraps a synchrounous or asynchrounous block that is executed by this button.
    ///
    enum Action {
        /// An action run synchrounously.
        case sync(() -> Void)

        /// An action run asynchrounously.
        case async(() async -> Void)
    }

    // MARK: Properties

    /// The accessibility label of the button.
    var accessibilityLabel: String

    /// The action to perform when the user interacts with this button.
    var action: Action

    /// The image to display in the button.
    var asset: ImageAsset

    var body: some View {
        switch action {
        case let .async(action):
            AsyncButton(action: action) {
                asset.swiftUIImage
                    .resizable()
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.accessory)
            .accessibilityLabel(Text(accessibilityLabel))
        case let .sync(action):
            Button(action: action) {
                asset.swiftUIImage
                    .resizable()
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.accessory)
            .accessibilityLabel(Text(accessibilityLabel))
        }
    }

    // MARK: Initialization

    /// Initializes a `AccessoryButton` which styles a button for display as an accessory to a
    /// field.
    ///
    /// - Parameters:
    ///   - asset: The image to display in the button.
    ///   - accessibilityLabel: The accessibility label of the button.
    ///   - action: The action to perform when the user triggers the button.
    ///
    init(asset: ImageAsset, accessibilityLabel: String, action: @escaping () -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.action = .sync(action)
        self.asset = asset
    }

    /// Initializes a `AccessoryButton` which styles a button for display as an accessory to a
    /// field.
    ///
    /// - Parameters:
    ///   - asset: The image to display in the button.
    ///   - accessibilityLabel: The accessibility label of the button.
    ///   - action: The action to perform when the user triggers the button.
    ///
    init(asset: ImageAsset, accessibilityLabel: String, action: @escaping () async -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.action = .async(action)
        self.asset = asset
    }
}

// MARK: Previews

#Preview {
    AccessoryButton(asset: Asset.Images.copy, accessibilityLabel: Localizations.copy) {}
}
