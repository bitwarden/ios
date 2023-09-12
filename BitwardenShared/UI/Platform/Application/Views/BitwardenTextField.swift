import SwiftUI

// MARK: - BitwardenTextField

/// A text field containing an optional trailing icon.
///
struct BitwardenTextField: View {
    // MARK: Properties

    /// The text content type used for the text field.
    var contentType: UITextContentType

    /// An optional trailing icon.
    var icon: Image?

    /// The text entered into the text field.
    @Binding var text: String

    /// The title of the text field.
    var title: String?

    // MARK: View

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let title {
                    Text(title)
                        .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                        .font(.system(.footnote))
                }

                ZStack {
                    if contentType == .password {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                            .textContentType(contentType)
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

                Divider()
            }

            Spacer()

            VStack {
                if let icon {
                    Button {
                        // Handled in BIT-272
                    } label: {
                        icon
                            .foregroundColor(Color(asset: Asset.Colors.primaryBitwarden))
                    }
                }
            }
        }
    }

    // MARK: Initialization

    /// Initializes a new `BitwardenTextField`.
    ///
    /// - Parameters:
    ///   - title: The title of the text field.
    ///   - icon: The text field's icon.
    ///   - contentType: The text content type used for the text field.
    ///   - text: The text entered into the text field.
    ///
    init(
        title: String? = nil,
        icon: Image? = nil,
        contentType: UITextContentType,
        text: Binding<String>
    ) {
        self.contentType = contentType
        self.icon = icon
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
            icon: Image(asset: Asset.Images.eye),
            contentType: .emailAddress,
            text: .constant("Text field text")
        )
        .padding()
        .previewDisplayName("With icon")

        BitwardenTextField(
            title: "Title",
            contentType: .emailAddress,
            text: .constant("Text field text")
        )
        .padding()
        .previewDisplayName("Without icon")
    }
}
#endif
