import Foundation
import SwiftUI
import ViewInspector

// swiftlint:disable file_length

/// A generic type wrapper around `ActionCard` to allow `ViewInspector` to find instances of
/// `ActionCard` without needing to know the details of it's implementation.
///
struct ActionCardType: BaseViewType {
    static var typePrefix: String = "ActionCard"

    static var namespacedPrefixes: [String] = [
        "BitwardenShared.ActionCard",
    ]
}

/// A generic type wrapper around `AsyncButton` to allow `ViewInspector` to find instances of `AsyncButton` without
/// needing to know the type of its `Label`.
///
struct AsyncButtonType: BaseViewType {
    static var typePrefix: String = "AsyncButton"

    static var namespacedPrefixes: [String] = [
        "BitwardenShared.AsyncButton",
    ]
}

/// A generic type wrapper around `BitwardenSlider` to allow `ViewInspector` to find instances of `BitwardenSlider`
/// without needing to know the details of it's implementation.
///
struct BitwardenSliderType: BaseViewType {
    static var typePrefix: String = "BitwardenSlider"

    static var namespacedPrefixes: [String] = [
        "BitwardenShared.BitwardenSlider",
    ]
}

/// A generic type wrapper around `BitwardenStepper` to allow `ViewInspector` to find instances of
/// `BitwardenStepper` without needing to know the details of it's implementation.
///
struct BitwardenStepperType: BaseViewType {
    static var typePrefix: String = "BitwardenStepper"

    static var namespacedPrefixes: [String] = [
        "BitwardenShared.BitwardenStepper",
    ]
}

/// A generic type wrapper around `BitwardenTextField` to allow `ViewInspector` to find instances of
/// `BitwardenTextField` without needing to know the details of it's implementation.
///
struct BitwardenTextFieldType: BaseViewType {
    static var typePrefix: String = "BitwardenTextField"

    static var namespacedPrefixes: [String] = [
        "BitwardenShared.BitwardenTextField",
    ]
}

/// A generic type wrapper around ` BitwardenMenuFieldType` to allow `ViewInspector` to find instances of
/// ` BitwardenMenuFieldType` without needing to know the details of it's implementation.
///
struct BitwardenMenuFieldType: BaseViewType {
    static var typePrefix: String = "BitwardenMenuField"

    static var namespacedPrefixes: [String] = [
        "BitwardenShared.BitwardenMenuField",
    ]
}

/// A generic type wrapper around `BitwardenUITextViewType` to allow `ViewInspector` to find
/// instances of `BitwardenUITextViewType` without needing to know the details of it's
/// implementation.
///
struct BitwardenUITextViewType: BaseViewType {
    static var typePrefix: String = "BitwardenUITextView"

    static var namespacedPrefixes: [String] = [
        "BitwardenShared.BitwardenUITextView",
    ]
}

/// A generic type wrapper around `FloatingActionButton` to allow `ViewInspector` to find instances
/// of `FloatingActionButton` without needing to know the details of it's implementation.
///
struct FloatingActionButtonType: BaseViewType {
    static var typePrefix: String = "FloatingActionButton"

    static var namespacedPrefixes: [String] = [
        "BitwardenShared.FloatingActionButton",
    ]
}

/// A generic type wrapper around `LoadingView` to allow `ViewInspector` to find instances of
/// `LoadingView` without needing to know the details of it's implementation.
///
struct LoadingViewType: BaseViewType {
    static var typePrefix: String = "LoadingView"

    static var namespacedPrefixes: [String] = [
        "BitwardenShared.LoadingView",
    ]
}

/// A generic type wrapper around `SettingsMenuField` to allow `ViewInspector` to find instances of
/// `SettingsMenuField` without needing to know the details of it's implementation.
///
struct SettingsMenuFieldType: BaseViewType {
    static var typePrefix: String = "SettingsMenuField"

    static var namespacedPrefixes: [String] = [
        "BitwardenShared.SettingsMenuField",
    ]
}

// MARK: InspectableView

extension InspectableView {
    // MARK: Methods

    /// Attempts to locate an action card with the provided title.
    ///
    /// - Parameters:
    ///   - title: The title to use while searching for a button.
    ///   - locale: The locale for text extraction.
    /// - Returns: An async button, if one can be located.
    /// - Throws: Throws an error if a view was unable to be located.
    ///
    func find(actionCard title: String) throws -> InspectableView<ActionCardType> {
        try find(ActionCardType.self, containing: title)
    }

    /// Attempts to locate an async button with the provided title.
    ///
    /// - Parameters:
    ///   - title: The title to use while searching for a button.
    ///   - locale: The locale for text extraction.
    /// - Returns: An async button, if one can be located.
    /// - Throws: Throws an error if a view was unable to be located.
    ///
    func find(
        asyncButton title: String,
        locale _: Locale = .testsDefault
    ) throws -> InspectableView<AsyncButtonType> {
        try find(AsyncButtonType.self, containing: title)
    }

    /// Attempts to locate an async button with the provided accessibility label.
    ///
    /// - Parameters:
    ///   - accessibilityLabel: The accessibility label to use while searching for a button.
    ///   - locale: The locale for text extraction.
    /// - Returns: A button, if one can be located.
    /// - Throws: Throws an error if a view was unable to be located.
    ///
    func find(
        asyncButtonWithAccessibilityLabel accessibilityLabel: String,
        locale: Locale = .testsDefault
    ) throws -> InspectableView<AsyncButtonType> {
        try find(AsyncButtonType.self) { view in
            try view.accessibilityLabel().string(locale: locale) == accessibilityLabel
        }
    }

    /// Attempts to locate a bitwarden menu field with the provided title.
    ///
    /// - Parameters:
    ///   - title: The title to use while searching for a menu field.
    ///   - locale: The locale for text extraction.
    /// - Returns: A `BitwardenMenuFieldType`, if one can be located.
    /// - Throws: Throws an error if a view was unable to be located.
    ///
    func find(
        bitwardenMenuField title: String,
        locale: Locale = .testsDefault
    ) throws -> InspectableView<BitwardenMenuFieldType> {
        try find(BitwardenMenuFieldType.self, containing: title, locale: locale)
    }

    /// Attempts to locate a bitwarden text field with the provided title.
    ///
    /// - Parameters:
    ///   - title: The title to use while searching for a text field.
    ///   - locale: The locale for text extraction.
    /// - Returns: A `BitwardenTextFieldType`, if one can be located.
    /// - Throws: Throws an error if a view was unable to be located.
    ///
    func find(
        bitwardenTextField title: String,
        locale: Locale = .testsDefault
    ) throws -> InspectableView<BitwardenTextFieldType> {
        try find(BitwardenTextFieldType.self, containing: title, locale: locale)
    }

    /// Attempts to locate an floating action button with the provided accessibility identifier.
    ///
    /// - Parameter accessibilityIdentifier: The accessibility identifier to use while searching for
    ///     a floating action button.
    /// - Returns: A floating action button, if one can be located.
    /// - Throws: Throws an error if a view was unable to be located.
    ///
    func find(
        floatingActionButtonWithAccessibilityIdentifier accessibilityIdentifier: String
    ) throws -> InspectableView<FloatingActionButtonType> {
        try find(FloatingActionButtonType.self) { view in
            try view.accessibilityIdentifier() == accessibilityIdentifier
        }
    }

    /// Attempts to locate a generic view with the provided accessibility label.
    ///
    /// - Parameters:
    ///   - type: The type of the view to locate.
    ///   - accessibilityLabel: The accessibility label to use while searching for the text field.
    ///   - locale: The locale for text extraction.
    /// - Returns: An `InspectableView` of the specified type, if one can be located.
    /// - Throws: Throws an error if a view was unable to be located.
    ///
    func find<T>(
        type: T.Type,
        accessibilityLabel: String,
        locale: Locale = .testsDefault
    ) throws -> InspectableView<T> {
        try find(T.self) { view in
            try view.accessibilityLabel().string(locale: locale) == accessibilityLabel
        }
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

    /// Attempts to locate a button with the provided accessibility label.
    ///
    /// - Parameter accessibilityLabel: The accessibility label to use while searching for a button.
    /// - Returns: A button, if one can be located.
    /// - Throws: Throws an error if a view was unable to be located.
    ///
    func find(
        buttonWithAccessibilityLabel accessibilityLabel: String,
        locale: Locale = .testsDefault
    ) throws -> InspectableView<ViewType.Button> {
        try find(ViewType.Button.self) { view in
            try view.accessibilityLabel().string(locale: locale) == accessibilityLabel
        }
    }

    /// Attempts to locate a picker with the provided label.
    ///
    /// - Parameter label: The label to use while searching for a picker.
    /// - Returns: A picker, if one can be located.
    /// - Throws: Throws an error if a picker was unable to be located.
    ///
    func find(
        picker label: String
    ) throws -> InspectableView<ViewType.Picker> {
        try find(ViewType.Picker.self, containing: label)
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

    /// Attempts to locate a settings menu field with the provided title.
    ///
    /// - Parameters:
    ///   - title: The title to use while searching for a menu field.
    ///   - locale: The locale for text extraction.
    /// - Returns: A `SettingsMenuField`, if one can be located.
    /// - Throws: Throws an error if a view was unable to be located.
    ///
    func find(
        settingsMenuField title: String,
        locale: Locale = .testsDefault
    ) throws -> InspectableView<SettingsMenuFieldType> {
        try find(SettingsMenuFieldType.self, containing: title, locale: locale)
    }

    /// Attempts to locate a slider with the provided accessibility label.
    ///
    /// - Parameter accessibilityLabel: The accessibility label to use while searching for a slider.
    /// - Returns: A slider, if one can be located.
    /// - Throws: Throws an error if a view was unable to be located.
    ///
    func find(
        sliderWithAccessibilityLabel accessibilityLabel: String,
        locale: Locale = .testsDefault
    ) throws -> InspectableView<BitwardenSliderType> {
        try find(BitwardenSliderType.self) { view in
            try view.accessibilityLabel().string(locale: locale) == accessibilityLabel
        }
    }

    /// Attempts to locate a toggle with the provided accessibility label.
    ///
    /// - Parameter accessibilityLabel: The accessibility label to use while searching for a toggle.
    /// - Returns: A toggle, if one can be located.
    /// - Throws: Throws an error if a view was unable to be located.
    ///
    func find(
        toggleWithAccessibilityLabel accessibilityLabel: String,
        locale: Locale = .testsDefault
    ) throws -> InspectableView<ViewType.Toggle> {
        try find(ViewType.Toggle.self) { view in
            try view.accessibilityLabel().string(locale: locale) == accessibilityLabel
        }
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

extension InspectableView where View == BitwardenTextFieldType {
    /// Locates the raw binding on this textfield's text value. Can be used to simulate updating the text field.
    ///
    func inputBinding() throws -> Binding<String> {
        let mirror = Mirror(reflecting: self)
        if let binding = mirror.descendant("content", "view", "_text") as? Binding<String> {
            return binding
        } else {
            throw InspectionError.attributeNotFound(
                label: "_text",
                type: String(describing: BitwardenTextFieldType.self)
            )
        }
    }
}

extension InspectableView where View == BitwardenSliderType {
    /// Simulates a drag gesture on the slider to set a new value.
    ///
    func setValue(_ value: Double) throws {
        let mirror = Mirror(reflecting: self)
        if let valueBinding = mirror.descendant("content", "view", "_value") as? Binding<Double>,
           let range = mirror.descendant("content", "view", "range") as? ClosedRange<Double>,
           let step = mirror.descendant("content", "view", "step") as? Double {
            // Calculate the new value based on the fraction
            let newValue = (range.upperBound - range.lowerBound + step) * value + range.lowerBound

            // Set the new value
            valueBinding.wrappedValue = newValue
        } else {
            throw InspectionError.attributeNotFound(
                label: "_value",
                type: String(describing: BitwardenSliderType.self)
            )
        }
    }
}

extension InspectableView where View == BitwardenUITextViewType {
    /// Locates the raw binding on this textfield's text value. Can be used to simulate updating the text field.
    ///
    func inputBinding() throws -> Binding<String> {
        let mirror = Mirror(reflecting: self)
        if let binding = mirror.descendant("content", "view", "_text") as? Binding<String> {
            return binding
        } else {
            throw InspectionError.attributeNotFound(
                label: "_text",
                type: String(describing: BitwardenUITextViewType.self)
            )
        }
    }
}

extension InspectableView where View == BitwardenMenuFieldType {
    /// Selects a new value in the menu field.
    ///
    func select(newValue: any Hashable) throws {
        let picker = try find(ViewType.Picker.self)
        try picker.select(value: newValue)
    }
}

extension InspectableView where View == SettingsMenuFieldType {
    /// Selects a new value in the menu field.
    ///
    func select(newValue: any Hashable) throws {
        let picker = try find(ViewType.Picker.self)
        try picker.select(value: newValue)
    }
}

extension InspectableView where View == BitwardenStepperType {
    /// Decrements the stepper.
    ///
    func decrement() throws {
        let button = try find(buttonWithId: "decrement")
        try button.tap()
    }

    /// Increments the stepper.
    ///
    func increment() throws {
        let button = try find(buttonWithId: "increment")
        try button.tap()
    }
}

extension InspectableView where View == FloatingActionButtonType {
    /// Simulates a tap on an `AsyncButton` within a `FloatingActionButton`. This method is
    /// asynchronous and allows the entire `async` `action` on the button to run before returning.
    ///
    @MainActor
    func tap() async throws {
        let button = try find(AsyncButtonType.self)
        try await button.tap()
    }
}
