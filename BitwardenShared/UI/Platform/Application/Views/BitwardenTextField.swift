import BitwardenResources
import SwiftUI
import SwiftUIIntrospect

// swiftlint:disable file_length

// MARK: - BitwardenTextField

/// The standard text field used within this application. The text field can be
/// configured to act as a password field with visibility toggling, and supports
/// displaying additional content on the trailing edge of the text field.
///
@MainActor
struct BitwardenTextField<FooterContent: View, TrailingContent: View>: View {
    // MARK: Private Properties

    /// A value indicating whether the textfield is currently enabled or disabled.
    @Environment(\.isEnabled) var isEnabled: Bool

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

    /// The (optional) footer content to display underneath the field.
    let footerContent: FooterContent?

    /// Whether a password in this text field is visible.
    let isPasswordVisible: Binding<Bool>?

    /// If the keyboard should be presented immediately when the view appears.
    let isPasswordAutoFocused: Bool

    /// If the text field should be disabled.
    let isTextFieldDisabled: Bool

    /// The accessibility identifier for the button to toggle password visibility.
    let passwordVisibilityAccessibilityId: String?

    /// The text entered into the text field.
    @Binding var text: String

    /// The title of the text field.
    let title: String?

    /// Optional content view that is displayed on the trailing edge of the field value.
    let trailingContent: TrailingContent?

    // MARK: View

    var body: some View {
        VStack(spacing: 0) {
            contentView

            footerView
        }
        .padding(.leading, 16)
        .background(
            isEnabled
                ? SharedAsset.Colors.backgroundSecondary.swiftUIColor
                : SharedAsset.Colors.backgroundSecondaryDisabled.swiftUIColor
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .contain)
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
        BitwardenFloatingTextLabel(
            title: title,
            isTextFieldDisabled: isTextFieldDisabled,
            showPlaceholder: showPlaceholder
        ) {
            textField
        } trailingContent: {
            HStack(spacing: 16) {
                if let isPasswordVisible, canViewPassword {
                    AccessoryButton(
                        asset: isPasswordVisible.wrappedValue
                            ? Asset.Images.eyeSlash24
                            : Asset.Images.eye24,
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
    }

    /// The view to display at a footer below the text field.
    @ViewBuilder private var footerView: some View {
        if let footer {
            VStack(alignment: .leading, spacing: 0) {
                Divider()

                Text(footer)
                    .styleGuide(.footnote, includeLinePadding: false, includeLineSpacing: false)
                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                    .padding(.trailing, 16)
                    .padding(.vertical, 12)
            }
        } else if let footerContent {
            footerContent
                // Apply trailing padding to the content, extend the frame the full width of view,
                // and add the divider in the background to ensure the divider is only shown if
                // there's content returned by the @ViewBuilder closure. Otherwise, an `if` block
                // in the closure that evaluates to false will have non-optional content but doesn't
                // display anything so the divider shouldn't be shown.
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(alignment: .top) {
                    Divider()
                }
        }
    }

    /// The text field.
    private var textField: some View {
        HStack(spacing: 8) {
            ZStack {
                let isPassword = isPasswordVisible != nil || canViewPassword == false
                let isPasswordVisible = isPasswordVisible?.wrappedValue ?? false
                TextField("", text: $text)
                    .focused($isTextFieldFocused)
                    .styleGuide(isPassword ? .bodyMonospaced : .body, includeLineSpacing: false)
                    // After some investigation, we found that .accessibilityIdentifier(..)
                    // calls should be placed before setting an id
                    // or hiding the field to avoid breaking accessibilityIds used on our mobile automation test suite
                    .accessibilityIdentifier(accessibilityIdentifier ?? "BitwardenTextField")
                    .hidden(!isPasswordVisible && isPassword)
                    .id(title)
                    .introspect(.textField, on: .iOS(.v15, .v16, .v17, .v18)) { textField in
                        textField.smartDashesType = isPassword ? .no : .default
                        textField.smartQuotesType = isPassword ? .no : .default
                    }
                    .accessibilityLabel(title ?? "")
                    .foregroundStyle(
                        isEnabled && !isTextFieldDisabled
                            ? SharedAsset.Colors.textPrimary.swiftUIColor
                            : SharedAsset.Colors.textDisabled.swiftUIColor
                    )
                    .disabled(isTextFieldDisabled)
                if isPassword, !isPasswordVisible {
                    SecureField("", text: $text)
                        .focused($isSecureFieldFocused)
                        .accessibilityIdentifier(accessibilityIdentifier ?? "BitwardenTextField")
                        .styleGuide(.bodyMonospaced, includeLineSpacing: false)
                        .id(title)
                        .accessibilityLabel(title ?? "")
                        .foregroundStyle(
                            isEnabled && !isTextFieldDisabled
                                ? SharedAsset.Colors.textPrimary.swiftUIColor
                                : SharedAsset.Colors.textDisabled.swiftUIColor
                        )
                }
            }
            .frame(maxWidth: .infinity, minHeight: 28)
        }
        .tint(SharedAsset.Colors.tintPrimary.swiftUIColor)
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
    ///   - isTextFieldDisabled: Whether the text field is disabled.
    ///   - trailingContent: Optional content view that is displayed on the trailing edge of the field.
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
        isTextFieldDisabled: Bool = false,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) where FooterContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.isPasswordAutoFocused = isPasswordAutoFocused
        self.isPasswordVisible = isPasswordVisible
        self.isTextFieldDisabled = isTextFieldDisabled
        self.footer = footer
        footerContent = nil
        self.canViewPassword = canViewPassword
        self.passwordVisibilityAccessibilityId = passwordVisibilityAccessibilityId
        _text = text
        self.title = title
        self.trailingContent = trailingContent()
    }

    /// Initializes a new `BitwardenTextField`.
    ///
    /// - Parameters:
    ///   - title: The title of the text field.
    ///   - text: The text entered into the text field.
    ///   - accessibilityIdentifier: The accessibility identifier for the text field.
    ///   - passwordVisibilityAccessibilityId: The accessibility ID for the button to toggle password visibility.
    ///   - canViewPassword: Whether the password can be viewed.
    ///   - isPasswordAutoFocused: Whether the password field shows the keyboard initially.
    ///   - isPasswordVisible: Whether the password is visible.
    ///   - isTextFieldDisabled: Whether the text field is disabled.
    ///   - trailingContent: Optional content view that is displayed on the trailing edge of the field.
    ///   - footerContent: The (optional) footer content to display underneath the field.
    ///
    init(
        title: String? = nil,
        text: Binding<String>,
        accessibilityIdentifier: String? = nil,
        passwordVisibilityAccessibilityId: String? = nil,
        canViewPassword: Bool = true,
        isPasswordAutoFocused: Bool = false,
        isPasswordVisible: Binding<Bool>? = nil,
        isTextFieldDisabled: Bool = false,
        @ViewBuilder trailingContent: () -> TrailingContent,
        @ViewBuilder footerContent: () -> FooterContent
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.isPasswordAutoFocused = isPasswordAutoFocused
        self.isPasswordVisible = isPasswordVisible
        self.isTextFieldDisabled = isTextFieldDisabled
        footer = nil
        self.footerContent = footerContent()
        self.canViewPassword = canViewPassword
        self.passwordVisibilityAccessibilityId = passwordVisibilityAccessibilityId
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
    ///   - isPasswordAutoFocused: Whether the password field shows the keyboard initially.
    ///   - isPasswordVisible: Whether the password is visible.
    ///   - isTextFieldDisabled: Whether the text field is disabled.
    ///   - footerContent: The (optional) footer content to display underneath the field.
    ///
    @_disfavoredOverload
    init(
        title: String? = nil,
        text: Binding<String>,
        accessibilityIdentifier: String? = nil,
        passwordVisibilityAccessibilityId: String? = nil,
        canViewPassword: Bool = true,
        isPasswordAutoFocused: Bool = false,
        isPasswordVisible: Binding<Bool>? = nil,
        isTextFieldDisabled: Bool = false,
        @ViewBuilder footerContent: () -> FooterContent
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.canViewPassword = canViewPassword
        footer = nil
        self.footerContent = footerContent()
        self.isPasswordAutoFocused = isPasswordAutoFocused
        self.isPasswordVisible = isPasswordVisible
        self.isTextFieldDisabled = isTextFieldDisabled
        self.passwordVisibilityAccessibilityId = passwordVisibilityAccessibilityId
        _text = text
        self.title = title
        trailingContent = nil
    }
}

extension BitwardenTextField where FooterContent == EmptyView, TrailingContent == EmptyView {
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
    ///   - isTextFieldDisabled: Whether the text field is disabled.
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
        isTextFieldDisabled: Bool = false
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.canViewPassword = canViewPassword
        self.footer = footer
        footerContent = nil
        self.isPasswordAutoFocused = isPasswordAutoFocused
        self.isPasswordVisible = isPasswordVisible
        self.isTextFieldDisabled = isTextFieldDisabled
        self.passwordVisibilityAccessibilityId = passwordVisibilityAccessibilityId
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
            AccessoryButton(asset: Asset.Images.cog24, accessibilityLabel: "") {}
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
            AccessoryButton(asset: Asset.Images.cog24, accessibilityLabel: "") {}
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Footer content") {
    VStack {
        BitwardenTextField(
            title: "Title",
            text: .constant("Text field text"),
            isPasswordVisible: .constant(false)
        ) {
            AccessoryButton(asset: Asset.Images.cog24, accessibilityLabel: "") {}
        } footerContent: {
            Button("Footer button") {}
                .buttonStyle(.bitwardenBorderless)
                .padding(.vertical, 14)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
#endif
