import SwiftUI

/// Helper functions extended off the `View` protocol.
///
extension View {
    /// A `ToolbarItem` for views with an add button.
    ///
    /// - Parameter action: The action to perform when the add button is tapped.
    ///
    /// - Returns: A `ToolbarItem` with an add button.
    ///
    func addToolbarItem(_ action: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            ToolbarButton(asset: Asset.Images.plus, label: Localizations.add, action: action)
        }
    }

    /// A `ToolbarItem` for views with a dismiss button.
    ///
    /// - Parameter action: The action to perform when the dismiss button is tapped.
    ///
    /// - Returns: A `ToolbarItem` with a dismiss button.
    ///
    func cancelToolbarItem(_ action: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            ToolbarButton(asset: Asset.Images.cancel, label: Localizations.cancel, action: action)
        }
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

    /// A `ToolbarItem` for views with a more button.
    ///
    /// - Parameter content: The content to display in the menu when the more icon is tapped.
    ///
    /// - Returns: A `ToolbarItem` with a more button that shows a menu.
    ///
    func moreToolbarItem(_ content: () -> some View) -> some ToolbarContent {
        ToolbarItem {
            Menu {
                content()
            } label: {
                Image(asset: Asset.Images.verticalKabob, label: Text(Localizations.options))
                    .resizable()
                    .frame(width: 19, height: 19)
                    .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
            }
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

    /// Applies the `ScrollViewModifier` to a view.
    ///
    /// - Returns: A view within a `ScrollView`.
    ///
    func scrollView() -> some View {
        modifier(ScrollViewModifier())
    }

    /// Applies a modifier to enable transparent scrolling in the scrollable view,
    /// Hides the background for scrollable views within the view.
    ///
    /// - Returns: A modified view that enables transparent scrolling.
    ///
    func transparentScrolling() -> some View {
        if #available(iOS 16.0, *) {
            return scrollContentBackground(.hidden)
        } else {
            return onAppear {
                // Set the background color of the UITextView to clear for transparent.
                UITextView.appearance().backgroundColor = .clear
            }
        }
    }
}
