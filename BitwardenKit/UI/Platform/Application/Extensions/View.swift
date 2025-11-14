import SwiftUI

// MARK: View+Extensions

/// Helper functions for fundamental `View` manipulation.
///
public extension View {
    // MARK: Computed Properties

    /// Wraps the view in a `NavigationStack`.
    ///
    @ViewBuilder var navStackWrapped: some View {
        if #available(iOSApplicationExtension 16.0, *) {
            NavigationStack { self }
        } else {
            NavigationView { self }
                .navigationViewStyle(.stack)
        }
    }

    // MARK: Methods

    /// Apply an arbitrary block of modifiers to a view. This is particularly useful
    /// if the modifiers in question might only be available on particular versions
    /// of iOS.
    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V {
        block(self)
    }

    /// Adds an async accessibility action to the view.
    ///
    /// - Parameters:
    ///   - name: The name of the action.
    ///   - asyncHandler: The async action.
    ///
    /// - Returns: A modified version of the content, with or without the accessibility action,
    ///    based on the supplied condition.
    ///
    func accessibilityAsyncAction<S>(
        named name: S,
        _ asyncHandler: @escaping () async -> Void,
    ) -> some View where S: StringProtocol {
        accessibilityAction(
            named: name, { Task { await asyncHandler() } },
        )
    }
}
