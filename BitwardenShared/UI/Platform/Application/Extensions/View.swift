import BitwardenResources
import SwiftUI

/// Helper functions extended off the `View` protocol.
///
extension View {
    /// Apply an arbitrary block of modifiers to a view. This is particularly useful
    /// if the modifiers in question might only be available on particular versions
    /// of iOS.
    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V {
        block(self)
    }

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

    /// Hides a view based on the specified value.
    ///
    /// NOTE: This should only be used when the view needs to remain in the view hierarchy while hidden,
    /// which is often useful for sizing purposes (e.g. hide or swap a view without resizing the parent).
    /// Otherwise, `if condition { view }` is preferred.
    ///
    /// - Parameter hidden: `true` if the view should be hidden.
    /// - Returns The original view if `hidden` is false, or the view with the hidden modifier applied.
    ///
    @ViewBuilder
    func hidden(_ hidden: Bool) -> some View {
        if hidden {
            self.hidden()
        } else {
            self
        }
    }

    /// Conditionally applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder
    func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }

    /// Applies a custom navigation bar title and title display mode to a view.
    ///
    /// - Parameters:
    ///   - title: The navigation bar title.
    ///   - titleDisplayMode: The navigation bar title display mode.
    ///
    /// - Returns: A view with a custom navigation bar.
    ///
    func navigationBar(
        title: String,
        titleDisplayMode: NavigationBarItem.TitleDisplayMode
    ) -> some View {
        modifier(NavigationBarViewModifier(
            title: title,
            navigationBarTitleDisplayMode: titleDisplayMode
        ))
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
        action: @escaping () async -> Void
    ) -> some View {
        floatingActionButton(
            hidden: hidden,
            image: Asset.Images.plus32.swiftUIImage,
            action: action
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
        action: @escaping (SendType) async -> Void
    ) -> some View {
        FloatingActionMenu(image: Asset.Images.plus32.swiftUIImage) {
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
        addFolder: (() -> Void)? = nil
    ) -> some View {
        FloatingActionMenu(image: Asset.Images.plus32.swiftUIImage) {
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
        action: @escaping () -> Void
    ) -> some View {
        floatingActionButton(
            hidden: hidden,
            image: Asset.Images.pencil32.swiftUIImage,
            action: action
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
        action: @escaping () async -> Void
    ) -> some View {
        FloatingActionButton(
            image: image,
            action: action
        )
        .padding([.trailing, .bottom], 16)
        .hidden(hidden)
    }
}
