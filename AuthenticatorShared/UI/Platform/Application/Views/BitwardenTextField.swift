import BitwardenResources
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

    /// Whether the password can be viewed (only applies if a password exists in the field).
    let canViewPassword: Bool

    /// The footer text displayed below the text field.
    let footer: String?

    /// Whether a password in this text field is visible.
    let isPasswordVisible: Binding<Bool>?

    /// The accessibility identifier for the button to toggle password visibility.
    let passwordVisibilityAccessibilityId: String?

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
        let isTrailingContentShown = isPasswordVisible != nil || trailingContent != nil
        if isTrailingContentShown {
            BitwardenField(title: title, footer: footer) {
                textField
            } accessoryContent: {
                if let isPasswordVisible, canViewPassword {
                    AccessoryButton(
                        asset: isPasswordVisible.wrappedValue
                            ? Asset.Images.hidden
                            : Asset.Images.visible,
                        accessibilityLabel: isPasswordVisible.wrappedValue
                            ? Localizations.passwordIsVisibleTapToHide
                            : Localizations.passwordIsNotVisibleTapToShow
                    ) {
                        isPasswordVisible.wrappedValue.toggle()
                    }
                    .accessibilityIdentifier(passwordVisibilityAccessibilityId ?? "TextVisibilityToggle")

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
                let isPassword = isPasswordVisible != nil
                let isPasswordVisible = isPasswordVisible?.wrappedValue ?? false

                TextField(placeholder, text: $text)
                    .focused($isTextFieldFocused)
                    .styleGuide(isPassword ? .bodyMonospaced : .body, includeLineSpacing: false)
                    .hidden(!isPasswordVisible && isPassword)
                    .id(title)
                if isPassword, !isPasswordVisible {
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
    ///   - passwordVisibilityAccessibilityId: The accessibility ID for the button to toggle password visibility.
    ///   - canViewPassword: Whether the password can be viewed.
    ///   - isPasswordVisible: Whether the password is visible.
    ///   - placeholder: An optional placeholder to display in the text field.
    ///
    init(
        title: String? = nil,
        text: Binding<String>,
        footer: String? = nil,
        accessibilityIdentifier: String? = nil,
        passwordVisibilityAccessibilityId: String? = nil,
        canViewPassword: Bool = true,
        isPasswordVisible: Binding<Bool>? = nil,
        placeholder: String? = nil,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.isPasswordVisible = isPasswordVisible
        self.footer = footer
        self.canViewPassword = canViewPassword
        self.passwordVisibilityAccessibilityId = passwordVisibilityAccessibilityId
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
    ///   - passwordVisibilityAccessibilityId: The accessibility ID for the button to toggle password visibility.
    ///   - canViewPassword: Whether the password can be viewed.
    ///   - isPasswordVisible: Whether the password is visible.
    ///   - placeholder: An optional placeholder to display in the text field.
    ///
    init(
        title: String? = nil,
        text: Binding<String>,
        footer: String? = nil,
        accessibilityIdentifier: String? = nil,
        passwordVisibilityAccessibilityId: String? = nil,
        canViewPassword: Bool = true,
        isPasswordVisible: Binding<Bool>? = nil,
        placeholder: String? = nil
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.canViewPassword = canViewPassword
        self.footer = footer
        self.isPasswordVisible = isPasswordVisible
        self.passwordVisibilityAccessibilityId = passwordVisibilityAccessibilityId
        self.placeholder = placeholder ?? ""
        _text = text
        self.title = title
        trailingContent = nil
    }
}

// MARK: Previews

#if DEBUG
#Preview("No buttons") {
    VStack {
        BitwardenTextField(
            title: "Title",
            text: .constant("Text field text")
        )
        .textContentType(.emailAddress)
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Password button") {
    VStack {
        BitwardenTextField(
            title: "Title",
            text: .constant("Text field text"),
            isPasswordVisible: .constant(false)
        )
        .textContentType(.password)
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Password revealed") {
    VStack {
        BitwardenTextField(
            title: "Title",
            text: .constant("Password"),
            isPasswordVisible: .constant(true)
        )
        .textContentType(.password)
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Additional buttons") {
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
}

#Preview("Footer text") {
    VStack {
        BitwardenTextField(
            title: "Title",
            text: .constant("Text field text"),
            footer: "Text field footer",
            isPasswordVisible: .constant(false)
        ) {
            AccessoryButton(asset: Asset.Images.gear, accessibilityLabel: "") {}
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
#endif
