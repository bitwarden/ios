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
        /// A wrapper around the action for this button to allow easily switching between sync and async actions.
        enum Action { // swiftlint:disable:this nesting
            /// A synchronous action.
            case sync(() -> Void)

            /// An asynchronous action.
            case async(() async -> Void)
        }

        /// The accessibility label for this button.
        var accessibilityLabel: String

        /// The action that is executed when this button is tapped.
        var action: Action

        /// The icon to display in this button.
        var icon: ImageAsset

        /// Creates a new `AccessoryButton`.
        ///
        /// - Parameters:
        ///   - accessibilityLabel: The accessibility label for this button.
        ///   - action: The synchronous action that is executed when this button is tapped.
        ///   - icon: The icon to display in this button.
        ///
        init(accessibilityLabel: String, action: @escaping () -> Void, icon: ImageAsset) {
            self.accessibilityLabel = accessibilityLabel
            self.action = .sync(action)
            self.icon = icon
        }

        /// Creates a new `AccessoryButton`.
        ///
        /// - Parameters:
        ///   - accessibilityLabel: The accessibility label for this button.
        ///   - action: The asynchronous action that is executed when this button is tapped.
        ///   - icon: The icon to display in this button.
        ///
        init(accessibilityLabel: String, action: @escaping () async -> Void, icon: ImageAsset) {
            self.accessibilityLabel = accessibilityLabel
            self.action = .async(action)
            self.icon = icon
        }
    }

    // MARK: Properties

    /// A list of additional buttons that appear on the trailing edge of a textfield.
    let buttons: [AccessoryButton]

    /// The footer text displayed below the text field.
    let footer: String?

    /// Whether a password in this text field is visible.
    let isPasswordVisible: Binding<Bool>?

    /// The placeholder that is displayed in the textfield.
    let placeholder: String

    /// The text entered into the text field.
    @Binding var text: String

    /// The title of the text field.
    let title: String?

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                textFieldTitle

                HStack(spacing: 8) {
                    textField
                    textFieldButtons
                }
            }

            if let footer {
                Text(footer)
                    .font(.styleGuide(.footnote))
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
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
        if isPasswordVisible != nil || !buttons.isEmpty {
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
                .font(.styleGuide(.subheadline))
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
    ///   - footer: The footer text displayed below the text field.
    ///   - isPasswordVisible: Whether or not the password in the text field is visible.
    ///   - placeholder: An optional placeholder to display in the text field.
    ///   - text: The text entered into the text field.
    ///
    init(
        title: String? = nil,
        buttons: [AccessoryButton] = [],
        footer: String? = nil,
        isPasswordVisible: Binding<Bool>? = nil,
        placeholder: String? = nil,
        text: Binding<String>
    ) {
        self.buttons = buttons
        self.footer = footer
        self.isPasswordVisible = isPasswordVisible
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
        let label = button.icon.swiftUIImage
            .resizable()
            .frame(width: 14, height: 14)
            .animation(nil, value: button.icon.swiftUIImage)
        switch button.action {
        case let .async(action):
            AsyncButton(role: nil, action: action, label: { label })
                .accessibilityLabel(button.accessibilityLabel)
                .buttonStyle(.accessory)
        case let .sync(action):
            Button(action: action, label: { label })
                .accessibilityLabel(button.accessibilityLabel)
                .buttonStyle(.accessory)
        }
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
                buttons: [
                    BitwardenTextField.AccessoryButton(
                        accessibilityLabel: "",
                        action: {},
                        icon: Asset.Images.cog
                    ),
                ],
                text: .constant("Text field text")
            )
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Additional buttons")

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
                footer: Localizations.vaultLockedMasterPassword,
                isPasswordVisible: .constant(false),
                text: .constant("Text field text")
            )
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Footer text")
    }
}
#endif
