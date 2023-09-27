import SwiftUI

struct BitwardenTextFieldButton {
    var accessibilityLabel: String
    var action: () -> Void
    var icon: ImageAsset
}

// MARK: - BitwardenTextField

/// A text field containing an optional trailing icon.
///
struct BitwardenTextField: View {
    // MARK: Properties

    /// The text content type used for the text field.
    let contentType: UITextContentType

    /// A list of additional buttons that appear on the trailing edge of a textfield.
    let buttons: [BitwardenTextFieldButton]

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
                    .textContentType(contentType)
                    .hidden(!isPasswordVisible && contentType == .password)
                if contentType == .password, !isPasswordVisible {
                    SecureField(placeholder, text: $text)
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

//    /// The text field's trailing icon.
//    @ViewBuilder private var textFieldIcon: some View {
//        if let icon {
//            Button {
//                isPasswordVisible.toggle()
//            } label: {
//                Image(asset: icon)
//                    .resizable()
//                    .frame(width: 24, height: 24)
//                    .foregroundColor(Color(asset: Asset.Colors.primaryBitwarden))
//                    .transaction { transaction in
//                        transaction.animation = nil
//                    }
//            }
//        }
//    }

    @ViewBuilder private var textFieldButtons: some View {
        if isPasswordVisible == nil, buttons.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 8) {
                if let isPasswordVisible {
                    textFieldButton(
                        BitwardenTextFieldButton(
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
                    textFieldButton(button)
                }
            }
        }
    }

    /// The title of the text field.
    @ViewBuilder private var textFieldTitle: some View {
        if let title {
            Text(title)
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                .font(.system(.footnote))
        }
    }

    // MARK: Initialization

    /// Initializes a new `BitwardenTextField`.
    ///
    /// - Parameters:
    ///   - title: The title of the text field.
    ///   - icon: The text field's icon.
    ///   - contentType: The text content type used for the text field.
    ///   - isPasswordVisible: Whether or not the password in the text field is visible.
    ///   - text: The text entered into the text field.
    ///
    init(
        title: String? = nil,
        buttons: [BitwardenTextFieldButton] = [],
        contentType: UITextContentType,
        isPasswordVisible: Binding<Bool>? = nil,
        placeholder: String? = nil,
        text: Binding<String>
    ) {
        self.buttons = buttons
        self.contentType = contentType
        self.isPasswordVisible = isPasswordVisible
        self.placeholder = placeholder ?? ""
        _text = text
        self.title = title
    }

    // MARK: Methods

    @ViewBuilder
    private func textFieldButton(_ button: BitwardenTextFieldButton) -> some View {
        Button(action: button.action) {
            button.icon.swiftUIImage
                .resizable()
                .frame(width: 14, height: 14)
                .padding(10)
                .foregroundColor(.white)
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
                buttons: [
                    BitwardenTextFieldButton(
                        accessibilityLabel: "",
                        action: {},
                        icon: Asset.Images.clock
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
