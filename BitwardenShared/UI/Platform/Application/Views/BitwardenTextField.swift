import SwiftUI

// MARK: - BitwardenTextField

/// The standard text field used within this application. The text field can be
/// configured to act as a password field with visibility toggling, and supports
/// displaying additional content on the trailing edge of the text field.
///
struct BitwardenTextField<TrailingContent: View>: View {
    // MARK: Private Properties

    /// A flag indicating if this field is currently focused.
    private var isFocused: Bool { isTextFieldFocused || isSecureFieldFocused }

    /// A flag indicating if the secure field is currently focused.
    @FocusState private var isSecureFieldFocused

    /// A flag indicating if the text field is currently focused.
    @FocusState private var isTextFieldFocused

    // MARK: Properties

    /// The accessibility identifier for the text field.
    let accessibilityIdentifier: String?

    /// Whether the text field text can be viewed (only applies if text exists in the field).
    let canViewTextFieldText: Bool

    /// The footer text displayed below the text field.
    let footer: String?

    /// Whether the text in this text field is visible.
    let isTextFieldTextVisible: Binding<Bool>?

    /// The accessibility identifier for the button to toggle text visibility.
    let textVisibilityAccessibilityId: String?

    /// The placeholder that is displayed in the textfield.
    let placeholder: String

    /// The text entered into the text field.
    @Binding var text: String

    /// The title of the text field.
    let title: String?

    /// Optional content view that is displayed on the trailing edge of the menu value.
    let trailingContent: TrailingContent?

    // MARK: View

    var body: some View {
        let isTrailingContentShown = isTextFieldTextVisible != nil || trailingContent != nil
        if isTrailingContentShown {
            BitwardenField(title: title, footer: footer) {
                textField
            } accessoryContent: {
                if let isTextFieldTextVisible, canViewTextFieldText {
                    AccessoryButton(
                        asset: isTextFieldTextVisible.wrappedValue
                            ? Asset.Images.hidden
                            : Asset.Images.visible,
                        accessibilityLabel: isTextFieldTextVisible.wrappedValue
                            ? Localizations.passwordIsVisibleTapToHide
                            : Localizations.passwordIsNotVisibleTapToShow
                    ) {
                        isTextFieldTextVisible.wrappedValue.toggle()
                    }
                    .accessibilityIdentifier(textVisibilityAccessibilityId ?? "TextVisibilityToggle")

                    if let trailingContent {
                        trailingContent
                    }
                } else if let trailingContent {
                    trailingContent
                }
            }
        } else {
            BitwardenField(title: title, footer: footer) {
                textField
            }
        }
    }

    // MARK: Private views

    /// The text field.
    private var textField: some View {
        HStack(spacing: 8) {
            ZStack {
                let isText = isTextFieldTextVisible != nil
                let isTextFieldTextVisible = isTextFieldTextVisible?.wrappedValue ?? false

                TextField(placeholder, text: $text)
                    .focused($isTextFieldFocused)
                    .styleGuide(isText ? .bodyMonospaced : .body, includeLineSpacing: false)
                    .hidden(!isTextFieldTextVisible && isText)
                    .id(title)
                if isText, !isTextFieldTextVisible {
                    SecureField(placeholder, text: $text)
                        .focused($isSecureFieldFocused)
                        .styleGuide(.bodyMonospaced, includeLineSpacing: false)
                        .id(title)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 28)
            .accessibilityIdentifier(accessibilityIdentifier ?? "BitwardenTextField")

            Button {
                text = ""
            } label: {
                Asset.Images.cancelRound.swiftUIImage
                    .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                    .frame(width: 14, height: 14)
            }
            .padding(.vertical, 5)
            .hidden(text.isEmpty || !isFocused)
        }
        .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
    }

    // MARK: Initialization

    /// Initializes a new `BitwardenTextField`.
    ///
    /// - Parameters:
    ///   - title: The title of the text field.
    ///   - footer: The footer text displayed below the text field.
    ///   - text: The text entered into the text field.
    ///   - accessibilityIdentifier: The accessibility identifier for the text field.
    ///   - canViewTextFieldText: Whether the text field text can be viewed.
    ///   - isTextFieldTextVisible: Whether the text in this text field is visible.
    ///   - textVisibilityAccessibilityId: The accessibility identifier for the
    ///     button to toggle text visibility.
    ///   - placeholder: An optional placeholder to display in the text field.
    ///
    init(
        title: String? = nil,
        text: Binding<String>,
        footer: String? = nil,
        accessibilityIdentifier: String? = nil,
        canViewTextFieldText: Bool = true,
        isTextFieldTextVisible: Binding<Bool>? = nil,
        textVisibilityAccessibilityId: String? = nil,
        placeholder: String? = nil,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.isTextFieldTextVisible = isTextFieldTextVisible
        self.footer = footer
        self.canViewTextFieldText = canViewTextFieldText
        self.textVisibilityAccessibilityId = textVisibilityAccessibilityId
        self.placeholder = placeholder ?? ""
        _text = text
        self.title = title
        self.trailingContent = trailingContent()
    }
}

extension BitwardenTextField where TrailingContent == EmptyView {
    /// Initializes a new `BitwardenTextField`.
    ///
    /// - Parameters:
    ///   - title: The title of the text field.
    ///   - footer: The footer text displayed below the text field.
    ///   - text: The text entered into the text field.
    ///   - accessibilityIdentifier: The accessibility identifier for the text field.
    ///   - canViewTextFieldText: Whether the text field text can be viewed.
    ///   - isTextFieldTextVisible: Whether the text in this text field is visible.
    ///   - textVisibilityAccessibilityId: The accessibility identifier for the
    ///     button to toggle text visibility.
    ///   - placeholder: An optional placeholder to display in the text field.
    ///
    init(
        title: String? = nil,
        text: Binding<String>,
        footer: String? = nil,
        accessibilityIdentifier: String? = nil,
        canViewTextFieldText: Bool = true,
        isTextFieldTextVisible: Binding<Bool>? = nil,
        textVisibilityAccessibilityId: String? = nil,
        placeholder: String? = nil
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.canViewTextFieldText = canViewTextFieldText
        self.footer = footer
        self.isTextFieldTextVisible = isTextFieldTextVisible
        self.textVisibilityAccessibilityId = textVisibilityAccessibilityId
        self.placeholder = placeholder ?? ""
        _text = text
        self.title = title
        trailingContent = nil
    }
}

// MARK: Previews

#if DEBUG
struct BitwardenTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BitwardenTextField(
                title: "Title",
                text: .constant("Text field text")
            )
            .textContentType(.emailAddress)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("No buttons")

        VStack {
            BitwardenTextField(
                title: "Title",
                text: .constant("Text field text"),
                isTextFieldTextVisible: .constant(false)
            )
            .textContentType(.password)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Password button")

        VStack {
            BitwardenTextField(
                title: "Title",
                text: .constant("Password"),
                isTextFieldTextVisible: .constant(true)
            )
            .textContentType(.password)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Password revealed")

        VStack {
            BitwardenTextField(
                title: "Title",
                text: .constant("Text field text")
            ) {
                AccessoryButton(asset: Asset.Images.gear, accessibilityLabel: "") {}
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Additional buttons")

        VStack {
            BitwardenTextField(
                title: "Title",
                text: .constant("Text field text"),
                footer: Localizations.vaultLockedMasterPassword,
                isTextFieldTextVisible: .constant(false)
            ) {
                AccessoryButton(asset: Asset.Images.gear, accessibilityLabel: "") {}
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Footer text")
    }
}
#endif
