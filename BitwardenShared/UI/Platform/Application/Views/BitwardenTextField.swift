import SwiftUI

// MARK: - BitwardenTextField

/// The standard text field used within this application. The text field can be
/// configured to act as a password field with visibility toggling, and supports
/// displaying configurable buttons on the trailing edge of the text field.
///
struct BitwardenTextField: View {
    // MARK: Types

    /// A type of button that is displayed within a `BitwardenTextField`.
    ///
    struct AccessoryButton {
        /// The accessibility label for this button.
        var accessibilityLabel: String

        /// The action that is executed when this button is tapped.
        var action: () -> Void

        /// The icon to display in this button.
        var icon: ImageAsset
    }

    // MARK: Properties

    /// The auto-capitalization type for the text field.
    let autoCaptializationType: TextInputAutocapitalization

    /// A list of additional buttons that appear on the trailing edge of a textfield.
    let buttons: [AccessoryButton]

    /// The text content type used for the text field.
    let contentType: UITextContentType

    /// Whether a password in this text field is visible.
    let isPasswordVisible: Binding<Bool>?

    /// The type of keyboard to use.
    let keyboardType: UIKeyboardType

    /// The placeholder that is displayed in the textfield.
    let placeholder: String

    /// The text entered into the text field.
    @Binding var text: String

    /// The title of the text field.
    let title: String?

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            textFieldTitle

            HStack(spacing: 8) {
                textField
                textFieldButtons
            }
        }
    }

    // MARK: Private views

    /// The text field.
    private var textField: some View {
        HStack(spacing: 8) {
            ZStack {
                let isPasswordVisible = isPasswordVisible?.wrappedValue ?? false

                TextField(placeholder, text: $text)
                    .hidden(!isPasswordVisible && contentType == .password)
                    .id(title)
                    .keyboardType(keyboardType)
                    .textContentType(contentType)
                    .textInputAutocapitalization(autoCaptializationType)
                if contentType == .password, !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                        .id(title)
                }
            }

            Button {
                text = ""
            } label: {
                Asset.Images.delete.swiftUIImage
                    .foregroundColor(.gray)
            }
            .hidden(text.isEmpty)
        }
        .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// The buttons displayed on the trailing edge of the text field.
    @ViewBuilder private var textFieldButtons: some View {
        if isPasswordVisible != nil || buttons.isEmpty {
            HStack(spacing: 8) {
                if let isPasswordVisible {
                    accessoryButton(
                        AccessoryButton(
                            accessibilityLabel: isPasswordVisible.wrappedValue
                                ? Localizations.passwordIsVisibleTapToHide
                                : Localizations.passwordIsNotVisibleTapToShow,
                            action: {
                                isPasswordVisible.wrappedValue.toggle()
                            },
                            icon: isPasswordVisible.wrappedValue
                                ? Asset.Images.eyeSlash
                                : Asset.Images.eye
                        )
                    )
                }

                ForEach(buttons, id: \.icon.name) { button in
                    accessoryButton(button)
                }
            }
        }
    }

    /// The title of the text field.
    @ViewBuilder private var textFieldTitle: some View {
        if let title {
            Text(title)
                .font(.system(.subheadline))
                .bold()
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
        }
    }

    // MARK: Initialization

    /// Initializes a new `BitwardenTextField`.
    ///
    /// - Parameters:
    ///   - title: The title of the text field.
    ///   - buttons: A list of additional buttons that appear on the trailing edge of a textfield.
    ///   - contentType: The text content type used for the text field.
    ///   - autoCaptializationType: The auto-capitalization type for the text field.
    ///   - keyboardType: The type of keyboard to use.
    ///   - isPasswordVisible: Whether or not the password in the text field is visible.
    ///   - placeholder: An optional placeholder to display in the text field.
    ///   - text: The text entered into the text field.
    ///
    init(
        title: String? = nil,
        buttons: [AccessoryButton] = [],
        contentType: UITextContentType,
        autoCapitalizationType: TextInputAutocapitalization = .sentences,
        keyboardType: UIKeyboardType = .default,
        isPasswordVisible: Binding<Bool>? = nil,
        placeholder: String? = nil,
        text: Binding<String>
    ) {
        autoCaptializationType = autoCapitalizationType
        self.buttons = buttons
        self.contentType = contentType
        self.isPasswordVisible = isPasswordVisible
        self.keyboardType = keyboardType
        self.placeholder = placeholder ?? ""
        _text = text
        self.title = title
    }

    // MARK: Methods

    /// Creates an accessory button.
    ///
    /// - Parameter button: The button information needed to create the accessory button.
    ///
    @ViewBuilder
    private func accessoryButton(_ button: AccessoryButton) -> some View {
        Button(action: button.action) {
            button.icon.swiftUIImage
                .resizable()
                .frame(width: 14, height: 14)
                .padding(10)
                .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                .background(Asset.Colors.fillTertiary.swiftUIColor)
                .clipShape(Circle())
                .transaction { transaction in
                    transaction.animation = nil
                }
        }
        .accessibilityLabel(button.accessibilityLabel)
    }
}

// MARK: Previews

#if DEBUG
struct BitwardenTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BitwardenTextField(
                title: "Title",
                contentType: .emailAddress,
                text: .constant("Text field text")
            )
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("No buttons")

        VStack {
            BitwardenTextField(
                title: "Title",
                contentType: .password,
                isPasswordVisible: .constant(false),
                text: .constant("Text field text")
            )
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Password button")

        VStack {
            BitwardenTextField(
                title: "Title",
                contentType: .password,
                isPasswordVisible: .constant(true),
                text: .constant("Password")
            )
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Password revealed")

        VStack {
            BitwardenTextField(
                title: "Title",
                buttons: [
                    BitwardenTextField.AccessoryButton(
                        accessibilityLabel: "",
                        action: {},
                        icon: Asset.Images.cog
                    ),
                ],
                contentType: .password,
                isPasswordVisible: .constant(false),
                text: .constant("Text field text")
            )
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Additional buttons")
    }
}
#endif
