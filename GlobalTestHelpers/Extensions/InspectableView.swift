import Foundation
import ViewInspector

/// A generic type wrapper around `AsyncButton` to allow `ViewInspector` to find instances of `AsyncButton` without
/// needing to know the type of its `Label`.
///
struct AsyncButtonType: BaseViewType {
    static var typePrefix: String = "AsyncButton"

    static var namespacedPrefixes: [String] = [
        "BitwardenShared.AsyncButton",
    ]
}

// MARK: InspectableView

extension InspectableView {
    // MARK: Methods

    /// Attempts to locate an async button with the provided title.
    ///
    /// - Parameter title: The title to use while searching for a button.
    /// - Returns: An async button, if one can be located.
    /// - Throws: Throws an error if a view was unable to be located.
    ///
    func find(asyncButton title: String) throws -> InspectableView<AsyncButtonType> {
        try find(AsyncButtonType.self, containing: title)
    }

    /// Attempts to locate a button with the provided id.
    ///
    /// - Parameter id: The id to use while searching for a button.
    /// - Returns: A button, if one can be located.
    /// - Throws: Throws an error if a view was unable to be located.
    ///
    func find(buttonWithId id: AnyHashable) throws -> InspectableView<ViewType.Button> {
        try find(ViewType.Button.self) { view in
            try view.id() == id
        }
    }

    func find(
        buttonWithAccessibilityLabel accessibilityLabel: String,
        locale: Locale = .testsDefault
    ) throws -> InspectableView<ViewType.Button> {
        try find(ViewType.Button.self) { view in
            try view.accessibilityLabel().string(locale: locale) == accessibilityLabel
        }
    }

    /// Attempts to locate a text field with the provided label.
    ///
    /// - Parameter label: The label to use while searching for a text field.
    /// - Returns: A text field, if one can be located.
    /// - Throws: Throws an error if a view was unable to be located.
    ///
    func find(textField label: String) throws -> InspectableView<ViewType.TextField> {
        try find(ViewType.TextField.self, containing: label)
    }

    /// Attempts to locate a secure field with the provided label.
    ///
    /// - Parameter label: The label to use while searching for a secure field.
    /// - Returns: A secure field, if one can be located.
    /// - Throws: Throws an error if a view was unable to be located.
    ///
    func find(secureField label: String) throws -> InspectableView<ViewType.SecureField> {
        try find(ViewType.SecureField.self, containing: label)
    }
}

extension InspectableView where View == AsyncButtonType {
    /// Simulates a tap on an `AsyncButton`. This method is asynchronous and allows the entire `async` `action` on the
    /// button to run before returning.
    ///
    func tap() async throws {
        typealias Callback = () async -> Void
        let mirror = Mirror(reflecting: self)
        if let action = mirror.descendant("content", "view", "action") as? Callback {
            await action()
        } else {
            throw InspectionError.attributeNotFound(
                label: "action",
                type: String(describing: AsyncButtonType.self)
            )
        }
    }
}
