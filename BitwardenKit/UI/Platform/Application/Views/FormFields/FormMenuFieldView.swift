import SwiftUI

// MARK: - FormMenuField

/// The data necessary for displaying a `FormMenuFieldView`.
///
public struct FormMenuField<State, T: Menuable>: Equatable, Identifiable {
    // MARK: Properties

    /// The accessibility identifier to apply to the field.
    let accessibilityIdentifier: String?

    /// The footer text displayed below the menu field.
    public let footer: String?

    /// A key path for updating the backing value for the menu field.
    let keyPath: WritableKeyPath<State, T>

    /// The options displayed in the menu.
    public let options: [T]

    /// The current selection.
    public let selection: T

    /// The title of the field.
    public let title: String

    // MARK: Identifiable

    public var id: String {
        "FormMenuField-\(title)"
    }

    // MARK: Initialization

    /// Initialize a `FormMenuField`.
    ///
    /// - Parameters:
    ///   - accessibilityIdentifier: The accessibility identifier given to the menu field.
    ///   - footer: The footer text displayed below the menu field.
    ///   - keyPath: A key path for updating the backing value for the menu field.
    ///   - options: The options displayed in the menu.
    ///   - selection: The current selection.
    ///   - title: The title of the field.
    public init(
        accessibilityIdentifier: String?,
        footer: String? = nil,
        keyPath: WritableKeyPath<State, T>,
        options: [T],
        selection: T,
        title: String,
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.footer = footer
        self.keyPath = keyPath
        self.options = options
        self.selection = selection
        self.title = title
    }
}

// MARK: - FormMenuFieldView

/// A view that displays a menu field for display in a form.
///
public struct FormMenuFieldView<State, T: Menuable, TitleAccessory: View, TrailingContent: View>: View {
    // MARK: Properties

    /// A closure containing the action to take when the menu selection is changed.
    let action: @Sendable (T) -> Void

    /// The data for displaying the field.
    let field: FormMenuField<State, T>

    /// Optional title accessory view that is displayed to the right of the title.
    let titleAccessoryContent: TitleAccessory?

    /// Optional content view that is displayed to the right of the menu value.
    let trailingContent: TrailingContent?

    // MARK: View

    public var body: some View {
        if let trailingContent, let titleAccessoryContent {
            BitwardenMenuField(
                title: field.title,
                footer: field.footer,
                accessibilityIdentifier: field.accessibilityIdentifier,
                options: field.options,
                selection: Binding(get: { field.selection }, set: action),
                titleAccessoryContent: { titleAccessoryContent },
                trailingContent: { trailingContent },
            )
        } else if let trailingContent {
            BitwardenMenuField(
                title: field.title,
                footer: field.footer,
                accessibilityIdentifier: field.accessibilityIdentifier,
                options: field.options,
                selection: Binding(get: { field.selection }, set: action),
                trailingContent: { trailingContent },
            )
        } else if let titleAccessoryContent {
            BitwardenMenuField(
                title: field.title,
                footer: field.footer,
                accessibilityIdentifier: field.accessibilityIdentifier,
                options: field.options,
                selection: Binding(get: { field.selection }, set: action),
                titleAccessoryContent: { titleAccessoryContent },
            )
        } else {
            BitwardenMenuField(
                title: field.title,
                footer: field.footer,
                accessibilityIdentifier: field.accessibilityIdentifier,
                options: field.options,
                selection: Binding(get: { field.selection }, set: action),
            )
        }
    }

    // MARK: Initialization

    /// Initialize a `FormMenuFieldView`.
    ///
    /// - Parameters:
    ///   - field:  The data for displaying the field.
    ///   - action: A closure containing the action to take when the menu selection is changed.
    ///
    public init(
        field: FormMenuField<State, T>,
        action: @Sendable @escaping (T) -> Void,
    ) where TrailingContent == EmptyView, TitleAccessory == EmptyView {
        self.action = action
        self.field = field
        trailingContent = nil
        titleAccessoryContent = nil
    }

    /// Initialize a `FormMenuFieldView`.
    ///
    /// - Parameters:
    ///   - field:  The data for displaying the field.
    ///   - action: A closure containing the action to take when the menu selection is changed.
    ///   - trailingContent: Optional content view that is displayed to the right of the menu value.
    ///
    public init(
        field: FormMenuField<State, T>,
        action: @Sendable @escaping (T) -> Void,
        trailingContent: @escaping () -> TrailingContent,
    ) where TitleAccessory == EmptyView {
        self.action = action
        self.field = field
        titleAccessoryContent = nil
        self.trailingContent = trailingContent()
    }

    /// Initialize a `FormMenuFieldView`.
    ///
    /// - Parameters:
    ///   - field:  The data for displaying the field.
    ///   - action: A closure containing the action to take when the menu selection is changed.
    ///   - titleAccessoryContent: Optional title accessory view that is displayed to the right of the title.
    ///
    public init(
        field: FormMenuField<State, T>,
        action: @Sendable @escaping (T) -> Void,
        titleAccessoryContent: @escaping () -> TitleAccessory,
    ) where TrailingContent == EmptyView {
        self.action = action
        self.field = field
        self.titleAccessoryContent = titleAccessoryContent()
        trailingContent = nil
    }

    /// Initialize a `FormMenuFieldView`.
    ///
    /// - Parameters:
    ///   - field:  The data for displaying the field.
    ///   - action: A closure containing the action to take when the menu selection is changed.
    ///   - titleAccessoryContent: Optional title accessory view that is displayed to the right of the title.
    ///   - trailingContent: Optional content view that is displayed to the right of the menu value.
    ///
    public init(
        field: FormMenuField<State, T>,
        action: @Sendable @escaping (T) -> Void,
        titleAccessoryContent: () -> TitleAccessory,
        trailingContent: @escaping () -> TrailingContent,
    ) {
        self.action = action
        self.field = field
        self.titleAccessoryContent = titleAccessoryContent()
        self.trailingContent = trailingContent()
    }
}
