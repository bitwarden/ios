import SwiftUI

/// Helper functions extended off the `View` protocol.
///
extension View {
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
}
