import Foundation
import SwiftUI

// MARK: - AsyncButton

/// A wrapper around SwiftUI's `Button` that allows you to perform an action asynchronously when the user
/// interacts with the button. This is especially helpful when the button's action instructs a `Store` to perform
/// an `Effect`.
///
struct AsyncButton<Label>: View where Label: View {
    // MARK: Properties

    /// The async action to perform when the user interacts with the button.
    let action: () async -> Void

    // MARK: Private Properties

    /// A view that describes the purpose of the button’s action.
    @ViewBuilder private var label: () -> Label

    /// An optional semantic role that describes the button.
    private let role: ButtonRole?

    var body: some View {
        Button(
            role: role,
            action: {
                Task {
                    await action()
                }
            },
            label: label
        )
    }

    // MARK: Initialization

    /// Creates a new `AsyncButton`.
    ///
    /// - Parameters:
    ///   - role: An optional semantic role that describes the button. A value of nil means that the button
    ///     doesn’t have an assigned role.
    ///   - action: The async action to perform when the user interacts with this button.
    ///   - label: A view that describes the purpose of the button’s action.
    ///
    init(
        role: ButtonRole? = nil,
        action: @escaping () async -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.role = role
        self.action = action
        self.label = label
    }
}

extension AsyncButton where Label == Text {
    /// Creates a new `AsyncButton`.
    ///
    /// - Parameters:
    ///   - titleKey: The key for the button's localized title, that describes the purpose of the button's
    ///     `action`.
    ///   - action: The async action to perform when the user interacts with this button.
    ///
    init(_ titleKey: LocalizedStringKey, action: @escaping () async -> Void) {
        self.init(action: action, label: { Text(titleKey) })
    }

    /// Creates a new `AsyncButton`.
    ///
    /// - Parameters:
    ///   - title: A string that describes the purpose of the button's `action`.
    ///   - role: An optional semantic role describing the button. A value of `nil` means that the button doesn't
    ///     have an assigned role.
    ///   - action: The async action to perform when the user interacts with this button.
    ///
    init<S>(_ title: S, role: ButtonRole? = nil, action: @escaping () async -> Void) where S: StringProtocol {
        self.init(action: action, label: { Text(title) })
    }
}
