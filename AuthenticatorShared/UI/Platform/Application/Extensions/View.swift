import SwiftUI

/// Helper functions extended off the `View` protocol.
///
extension View {
    @ViewBuilder var navStackWrapped: some View {
        if #available(iOSApplicationExtension 16.0, *) {
            NavigationStack { self }
        } else {
            NavigationView { self }
                .navigationViewStyle(.stack)
        }
    }

    /// On iOS 16+, configures the scroll view to dismiss the keyboard immediately.
    ///
    func dismissKeyboardImmediately() -> some View {
        if #available(iOSApplicationExtension 16, *) {
            return self.scrollDismissesKeyboard(.immediately)
        } else {
            return self
        }
    }

    /// On iOS 16+, configures the scroll view to dismiss the keyboard interactively.
    ///
    func dismissKeyboardInteractively() -> some View {
        if #available(iOSApplicationExtension 16, *) {
            return self.scrollDismissesKeyboard(.interactively)
        } else {
            return self
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
    /// - Parameter addVerticalPadding: Whether or not to add vertical padding. Defaults to `true`.
    ///
    /// - Returns: A view within a `ScrollView`.
    ///
    func scrollView(addVerticalPadding: Bool = true) -> some View {
        modifier(ScrollViewModifier(addVerticalPadding: addVerticalPadding))
    }
}
