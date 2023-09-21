import SwiftUI

// MARK: - BitwardenTextField

/// A text field containing an optional trailing icon.
///
struct BitwardenTextField: View {
    // MARK: Properties

    /// The text content type used for the text field.
    let contentType: UITextContentType

    /// An optional trailing icon.
    let icon: ImageAsset?

    /// Whether a password in this text field is visible.
    @Binding var isPasswordVisible: Bool

    /// The text entered into the text field.
    @Binding var text: String

    /// The title of the text field.
    let title: String?

    // MARK: View

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                textFieldTitle

                textField

                Divider()
            }

            Spacer()

            textFieldIcon
        }
    }

    // MARK: Private views

    /// The text field.
    private var textField: some View {
        ZStack {
            TextField("", text: $text)
                .textContentType(contentType)
                .hidden(!isPasswordVisible && contentType == .password)
            if contentType == .password, !isPasswordVisible {
                SecureField("", text: $text)
            }

            HStack {
                Spacer()

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(asset: Asset.Images.delete)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    /// The text field's trailing icon.
    @ViewBuilder private var textFieldIcon: some View {
        if let icon {
            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(asset: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color(asset: Asset.Colors.primaryBitwarden))
                    .transaction { transaction in
                        transaction.animation = nil
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
        icon: ImageAsset? = nil,
        contentType: UITextContentType,
        isPasswordVisible: Binding<Bool>? = nil,
        text: Binding<String>
    ) {
        self.contentType = contentType
        self.icon = icon
        _isPasswordVisible = isPasswordVisible ?? .constant(false)
        _text = text
        self.title = title
    }
}

// MARK: Previews

#if DEBUG
struct BitwardenTextField_Previews: PreviewProvider {
    static var previews: some View {
        BitwardenTextField(
            title: "Title",
            icon: Asset.Images.eye,
            contentType: .emailAddress,
            isPasswordVisible: .constant(false),
            text: .constant("Text field text")
        )
        .padding()
        .previewDisplayName("With icon")

        BitwardenTextField(
            title: "Title",
            contentType: .emailAddress,
            isPasswordVisible: .constant(true),
            text: .constant("Text field text")
        )
        .padding()
        .previewDisplayName("Without icon")
    }
}
#endif
