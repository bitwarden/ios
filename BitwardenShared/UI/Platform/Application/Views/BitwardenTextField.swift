import SwiftUI
import SwiftUIIntrospect

// MARK: - BitwardenTextField

/// The standard text field used within this application. The text field can be
/// configured to act as a password field with visibility toggling, and supports
/// displaying additional content on the trailing edge of the text field.
///
@MainActor
struct BitwardenTextField<TrailingContent: View>: View {
    // MARK: Private Properties

    /// A flag indicating if this field is currently focused.
    private var isFocused: Bool { isTextFieldFocused || isSecureFieldFocused }

    /// A flag indicating if the secure field is currently focused.
    @FocusState private var isSecureFieldFocused

    /// A flag indicating if the text field is currently focused.
    @FocusState private var isTextFieldFocused

    /// Whether the placeholder text should be shown in the text field.
    private var showPlaceholder: Bool {
        !isFocused && text.isEmpty
    }

    // MARK: Properties

    /// The accessibility identifier for the text field.
    let accessibilityIdentifier: String?

    /// Whether the password can be viewed (only applies if a password exists in the field).
    let canViewPassword: Bool

    /// The footer text displayed below the text field.
    let footer: String?

    /// Whether a password in this text field is visible.
    let isPasswordVisible: Binding<Bool>?

    /// If the keyboard should be presented immediately when the view appears.
    let isPasswordAutoFocused: Bool

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
        VStack(spacing: 0) {
            contentView

            footerView
        }
        .padding(.leading, 16)
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            let isPassword = isPasswordVisible != nil || canViewPassword == false
            let isPasswordVisible = isPasswordVisible?.wrappedValue ?? false
            if isPassword, !isPasswordVisible {
                isSecureFieldFocused = true
            } else {
                isTextFieldFocused = true
            }
        }
    }

    // MARK: Private views

    /// The main content for the view, containing the title label and text field.
    @ViewBuilder private var contentView: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                // This preserves space for the title to lay out above the text field when
                // it transitions from the centered to top position. But it's always hidden and
                // the text above is the one that moves during the transition.
                titleText(showPlaceholder: false)
                    .hidden()

                textField
            }
            .overlay(alignment: showPlaceholder ? .leading : .topLeading) {
                // The placeholder and title text which is vertically centered in the view when the
                // text field doesn't have focus and is empty and otherwise displays above the text field.
                titleText(showPlaceholder: showPlaceholder)
            }

            HStack(spacing: 16) {
                if let isPasswordVisible, canViewPassword {
                    AccessoryButton(
                        asset: isPasswordVisible.wrappedValue
                            ? Asset.Images.eyeSlash16
                            : Asset.Images.eye16,
                        accessibilityLabel: isPasswordVisible.wrappedValue
                            ? Localizations.passwordIsVisibleTapToHide
                            : Localizations.passwordIsNotVisibleTapToShow
                    ) {
                        isPasswordVisible.wrappedValue.toggle()
                    }
                    .accessibilityIdentifier(passwordVisibilityAccessibilityId ?? "TextVisibilityToggle")
                }

                trailingContent
            }
        }
        .animation(.linear(duration: 0.1), value: isFocused)
        .padding(.trailing, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 64)
    }

    /// The view to display at a footer below the text field.
    @ViewBuilder private var footerView: some View {
        if let footer {
            VStack(alignment: .leading, spacing: 0) {
                Divider()

                Text(footer)
                    .styleGuide(.footnote, includeLinePadding: false, includeLineSpacing: false)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .padding(.trailing, 16)
                    .padding(.vertical, 12)
            }
        }
    }

    /// The text field.
    private var textField: some View {
        HStack(spacing: 8) {
            ZStack {
                let isPassword = isPasswordVisible != nil || canViewPassword == false
                let isPasswordVisible = isPasswordVisible?.wrappedValue ?? false

                TextField(placeholder, text: $text)
                    .focused($isTextFieldFocused)
                    .styleGuide(isPassword ? .bodyMonospaced : .body, includeLineSpacing: false)
                    .hidden(!isPasswordVisible && isPassword)
                    .id(title)
                    .introspect(.textField, on: .iOS(.v15, .v16, .v17, .v18)) { textField in
                        textField.smartDashesType = isPassword ? .no : .default
                    }
                if isPassword, !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                        .focused($isSecureFieldFocused)
                        .styleGuide(.bodyMonospaced, includeLineSpacing: false)
                        .id(title)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 28)
            .accessibilityIdentifier(accessibilityIdentifier ?? "BitwardenTextField")
        }
        .tint(Asset.Colors.tintPrimary.swiftUIColor)
        .onAppear {
            isSecureFieldFocused = isPasswordAutoFocused
        }
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
    ///   - isPasswordAutoFocused: Whether the password field shows the keyboard initially.
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
        isPasswordAutoFocused: Bool = false,
        isPasswordVisible: Binding<Bool>? = nil,
        placeholder: String? = nil,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.isPasswordAutoFocused = isPasswordAutoFocused
        self.isPasswordVisible = isPasswordVisible
        self.footer = footer
        self.canViewPassword = canViewPassword
        self.passwordVisibilityAccessibilityId = passwordVisibilityAccessibilityId
        self.placeholder = placeholder ?? ""
        _text = text
        self.title = title
        self.trailingContent = trailingContent()
    }

    // MARK: Private

    /// The title/placeholder text for the field.
    @ViewBuilder
    private func titleText(showPlaceholder: Bool) -> some View {
        if let title {
            Text(title)
                .styleGuide(
                    showPlaceholder ? .body : .subheadline,
                    weight: showPlaceholder ? .regular : .semibold, // semibold ??
                    includeLinePadding: false,
                    includeLineSpacing: false
                )
                .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
        }
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
    ///   - isPasswordAutoFocused: Whether the password field shows the keyboard initially.
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
        isPasswordAutoFocused: Bool = false,
        isPasswordVisible: Binding<Bool>? = nil,
        placeholder: String? = nil
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.canViewPassword = canViewPassword
        self.footer = footer
        self.isPasswordAutoFocused = isPasswordAutoFocused
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
            AccessoryButton(asset: Asset.Images.cog16, accessibilityLabel: "") {}
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
            footer: Localizations.vaultLockedMasterPassword,
            isPasswordVisible: .constant(false)
        ) {
            AccessoryButton(asset: Asset.Images.cog16, accessibilityLabel: "") {}
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
#endif
