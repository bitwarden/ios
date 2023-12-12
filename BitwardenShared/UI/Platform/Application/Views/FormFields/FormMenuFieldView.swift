import SwiftUI

// MARK: - FormMenuField

/// The data necessary for displaying a `FormMenuFieldView`.
///
struct FormMenuField<State, T: Menuable>: Equatable, Identifiable {
    // MARK: Properties

    /// The footer text displayed below the menu field.
    let footer: String?

    /// A key path for updating the backing value for the menu field.
    let keyPath: WritableKeyPath<State, T>

    /// The options displayed in the menu.
    let options: [T]

    /// The current selection.
    let selection: T

    /// The title of the field.
    let title: String

    // MARK: Identifiable

    var id: String {
        "FormMenuField-\(title)"
    }

    // MARK: Initialization

    /// Initialize a `FormMenuField`.
    ///
    /// - Parameters:
    ///   - footer: The footer text displayed below the menu field.
    ///   - keyPath: A key path for updating the backing value for the menu field.
    ///   - options: The options displayed in the menu.
    ///   - selection: The current selection.
    ///   - title: The title of the field.
    init(
        footer: String? = nil,
        keyPath: WritableKeyPath<State, T>,
        options: [T],
        selection: T,
        title: String
    ) {
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
struct FormMenuFieldView<State, T: Menuable, TrailingContent: View>: View {
    // MARK: Properties

    /// A closure containing the action to take when the menu selection is changed.
    let action: (T) -> Void

    /// The data for displaying the field.
    let field: FormMenuField<State, T>

    /// Optional content view that is displayed to the right of the menu value.
    let trailingContent: TrailingContent

    // MARK: View

    var body: some View {
        BitwardenMenuField(
            title: field.title,
            footer: field.footer,
            options: field.options,
            selection: Binding(get: { field.selection }, set: action),
            trailingContent: { trailingContent }
        )
    }

    // MARK: Initialization

    /// Initialize a `FormMenuFieldView`.
    ///
    /// - Parameters:
    ///   - field:  The data for displaying the field.
    ///   - action: A closure containing the action to take when the menu selection is changed.
    ///
    init(
        field: FormMenuField<State, T>,
        action: @escaping (T) -> Void
    ) where TrailingContent == EmptyView {
        self.action = action
        self.field = field
        trailingContent = EmptyView()
    }

    /// Initialize a `FormMenuFieldView`.
    ///
    /// - Parameters:
    ///   - field:  The data for displaying the field.
    ///   - action: A closure containing the action to take when the menu selection is changed.
    ///   - trailingContent: Optional content view that is displayed to the right of the menu value.
    ///
    init(
        field: FormMenuField<State, T>,
        action: @escaping (T) -> Void,
        trailingContent: @escaping () -> TrailingContent
    ) {
        self.action = action
        self.field = field
        self.trailingContent = trailingContent()
    }
}
