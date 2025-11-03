import BitwardenKit
import BitwardenResources
import SwiftUI

/// Helper functions extended off the `View` protocol.
///
extension View {
    /// Focuses next field in sequence, from the given `FocusState`.
    /// Requires a currently active focus state and a next field available in the sequence.
    /// (https://stackoverflow.com/a/71531523)
    ///
    /// Example usage:
    /// ```
    /// .onSubmit { self.focusNextField($focusedField) }
    /// ```
    /// Given that `focusField` is an enum that represents the focusable fields. For example:
    /// ```
    /// @FocusState private var focusedField: Field?
    /// enum Field: Int, Hashable {
    ///    case name
    ///    case country
    ///    case city
    /// }
    /// ```
    ///
    /// - Parameter field: next field to be focused.
    ///
    func focusNextField<F: RawRepresentable>(_ field: FocusState<F?>.Binding) where F.RawValue == Int {
        guard let currentValue = field.wrappedValue else { return }
        let nextValue = currentValue.rawValue + 1
        if let newValue = F(rawValue: nextValue) {
            field.wrappedValue = newValue
        }
    }

    /// Returns a floating action button positioned at the bottom-right corner of the screen.
    ///
    /// - Parameters:
    ///   - hidden: Whether the button should be hidden.
    ///   - action: The action to perform when the button is tapped.
    /// - Returns: A `FloatingActionButton` configured for adding an item.
    ///
    func addItemFloatingActionButton(
        hidden: Bool = false,
        action: @escaping () async -> Void,
    ) -> some View {
        floatingActionButton(
            hidden: hidden,
            image: SharedAsset.Icons.plus32.swiftUIImage,
            action: action,
        )
        .accessibilityLabel(Localizations.add)
        .accessibilityIdentifier("AddItemFloatingActionButton")
    }

    /// Returns a floating action menu positioned at the bottom-right corner of the screen for
    /// adding a send item.
    ///
    /// - Parameters:
    ///   - hidden: Whether the menu button should be hidden.
    ///   - action: The action to perform when a send type is tapped in the menu.
    /// - Returns: A `FloatingActionMenu` configured for adding a send item.
    ///
    func addSendItemFloatingActionMenu(
        hidden: Bool = false,
        action: @escaping (SendType) async -> Void,
    ) -> some View {
        FloatingActionMenu(image: SharedAsset.Icons.plus32.swiftUIImage) {
            ForEach(SendType.allCases) { type in
                AsyncButton(type.localizedName) {
                    await action(type)
                }
            }
        }
        .accessibilityLabel(Localizations.add)
        .accessibilityIdentifier("AddItemFloatingActionButton")
        .padding([.trailing, .bottom], 16)
    }

    /// Returns a floating action menu positioned at the bottom-right corner of the screen.
    ///
    /// - Parameters:
    ///   - hidden: Whether the menu button should be hidden.
    ///   - availableItemTypes: The list of cipher item types available for creation.
    ///   - addItem: The action to perform when a new cipher item type is tapped in the menu.
    ///   - addFolder: The action to perform when the new folder button is tapped in the menu.
    /// - Returns: A `FloatingActionMenu` configured for adding a vault item for folder.
    ///
    func addVaultItemFloatingActionMenu(
        hidden: Bool = false,
        availableItemTypes: [CipherType] = CipherType.canCreateCases,
        addItem: @escaping (CipherType) -> Void,
        addFolder: (() -> Void)? = nil,
    ) -> some View {
        FloatingActionMenu(image: SharedAsset.Icons.plus32.swiftUIImage) {
            // The items in the menu are added in reverse order so that when the context menu
            // displays above the button, which is the common case, the types are at the top with
            // folder at the bottom.

            if let addFolder {
                Button(Localizations.folder, action: addFolder)
                Divider()
            }

            ForEach(availableItemTypes, id: \.hashValue) { type in
                Button(type.localizedName) {
                    addItem(type)
                }
            }
        }
        .accessibilityLabel(Localizations.add)
        .accessibilityIdentifier("AddItemFloatingActionButton")
        .padding([.trailing, .bottom], 16)
        .hidden(hidden)
    }

    /// Returns a floating action button positioned at the bottom-right corner of the screen.
    ///
    /// - Parameters:
    ///   - hidden: Whether the button should be hidden.
    ///   - action: The action to perform when the button is tapped.
    /// - Returns: A `FloatingActionButton` configured for adding an item.
    ///
    func editItemFloatingActionButton(
        hidden: Bool = false,
        action: @escaping () -> Void,
    ) -> some View {
        floatingActionButton(
            hidden: hidden,
            image: SharedAsset.Icons.pencil32.swiftUIImage,
            action: action,
        )
        .accessibilityLabel(Localizations.edit)
        .accessibilityIdentifier("EditItemFloatingActionButton")
    }

    /// Returns a floating action button positioned at the bottom-right corner of the screen.
    ///
    /// - Parameters:
    ///   - hidden: Whether the button should be hidden.
    ///   - image: The image to display within the button.
    ///   - action: The action to perform when the button is tapped.
    /// - Returns: A `FloatingActionButton` configured with the specified image and action.
    ///
    func floatingActionButton(
        hidden: Bool = false,
        image: Image,
        action: @escaping () async -> Void,
    ) -> some View {
        FloatingActionButton(
            image: image,
            action: action,
        )
        .padding([.trailing, .bottom], 16)
        .hidden(hidden)
    }
}
