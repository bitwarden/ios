import SwiftUI

// MARK: - BitwardenTextField

/// The standard text field used within this application. The text field can be
/// configured to act as a password field with visibility toggling, and supports
/// displaying additional content on the trailing edge of the text field.
///
struct BitwardenTextField<TrailingContent: View>: View {
    // MARK: Properties

    /// The accessibility identifier for the text field.
    let accessibilityIdentifier: String?

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
            BitwardenField(title: title, footer: footer, verticalPadding: 8) {
                textField
            } accessoryContent: {
                if let isPasswordVisible {
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
                    .accessibilityIdentifier(passwordVisibilityAccessibilityId ?? "PasswordVisibilityToggle")

                    if let trailingContent {
                        trailingContent
                    }
                } else if let trailingContent {
                    trailingContent
                }
            }
        } else {
            BitwardenField(title: title, footer: footer, verticalPadding: 8) {
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
                    .font(.styleGuide(isPassword ? .bodyMonospaced : .body))
                    .hidden(!isPasswordVisible && isPassword)
                    .id(title)
                if isPassword, !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                        .id(title)
                }
            }
            .accessibilityIdentifier(accessibilityIdentifier ?? "BitwardenTextField")

            Button {
                text = ""
            } label: {
                Asset.Images.cancelRound.swiftUIImage
                    .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                    .frame(width: 14, height: 14)
            }
            .padding(.vertical, 5)
            .hidden(text.isEmpty)
        }
        .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
    }

    // MARK: Initialization

    /// Initializes a new `BitwardenTextField`.
    ///
    /// - Parameters:
    ///   - accessibilityIdentifier: The accessibility identifier for the text field.
    ///   - title: The title of the text field.
    ///   - footer: The footer text displayed below the text field.
    ///   - isPasswordVisible: Whether or not the password in the text field is visible.
    ///   - passwordVisibilityAccessibilityId: The accessibility identifier for the
    ///     button to toggle password visibility.
    ///   - placeholder: An optional placeholder to display in the text field.
    ///   - text: The text entered into the text field.
    ///
    init(
        accessibilityIdentifier: String? = nil,
        title: String? = nil,
        footer: String? = nil,
        isPasswordVisible: Binding<Bool>? = nil,
        passwordVisibilityAccessibilityId: String? = nil,
        placeholder: String? = nil,
        text: Binding<String>,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.footer = footer
        self.isPasswordVisible = isPasswordVisible
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
    ///   - accessibilityIdentifier: The accessibility identifier for the text field.
    ///   - title: The title of the text field.
    ///   - footer: The footer text displayed below the text field.
    ///   - isPasswordVisible: Whether or not the password in the text field is visible.
    ///   - passwordVisibilityAccessibilityId: The accessibility identifier for the
    ///     button to toggle password visibility.
    ///   - placeholder: An optional placeholder to display in the text field.
    ///   - text: The text entered into the text field.
    ///
    init(
        accessibilityIdentifier: String? = nil,
        title: String? = nil,
        footer: String? = nil,
        isPasswordVisible: Binding<Bool>? = nil,
        passwordVisibilityAccessibilityId: String? = nil,
        placeholder: String? = nil,
        text: Binding<String>
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
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
                isPasswordVisible: .constant(false),
                text: .constant("Text field text")
            )
            .textContentType(.password)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Password button")

        VStack {
            BitwardenTextField(
                title: "Title",
                isPasswordVisible: .constant(true),
                text: .constant("Password")
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
                footer: Localizations.vaultLockedMasterPassword,
                isPasswordVisible: .constant(false),
                text: .constant("Text field text")
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
