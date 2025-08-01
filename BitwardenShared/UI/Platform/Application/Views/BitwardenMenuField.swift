import BitwardenResources
import SwiftUI

// MARK: - Menuable

/// A protocol that defines an object that can be represented and selected in
/// a `BitwardenMenuField`.
protocol Menuable: Equatable, Hashable {
    ///  The custom localizable title value for this default case, defaults to  `Default`.
    static var defaultValueLocalizedName: String { get }

    /// The accessibility identifier for the menu option.
    var accessibilityId: String { get }

    /// A localized name value. This value is displayed in the Menu when the user
    /// is making a selection between multiple options.
    var localizedName: String { get }
}

extension Menuable {
    static var defaultValueLocalizedName: String {
        Localizations.default
    }

    var accessibilityId: String {
        localizedName
    }
}

// MARK: - BitwardenMenuField

/// A standard input field that allows the user to select between a predefined set of
/// options. This view is identical to `BitwardenTextField`, but uses a `Menu`
/// instead of a `TextField` as the input mechanism.
///
struct BitwardenMenuField<
    T,
    AdditionalMenu: View,
    TitleAccessory: View,
    TrailingContent: View
>: View where T: Menuable {
    // MARK: Properties

    /// The selection chosen from the menu.
    @Binding var selection: T

    /// The width of the title label.
    @SwiftUI.State var titleWidth: CGFloat = 0

    /// The accessibility identifier for the view.
    let accessibilityIdentifier: String?

    /// Additional menu options to display in the menu, separated from the list of options.
    let additionalMenu: AdditionalMenu?

    /// Whether the view allows user interaction.
    @Environment(\.isEnabled) var isEnabled: Bool

    /// The options displayed in the menu.
    let options: [T]

    /// The footer text displayed below the menu field.
    let footer: String?

    /// The title of the menu field.
    let title: String?

    /// Optional title accessory content view that is displayed on the trailing edge of the title.
    let titleAccessoryContent: TitleAccessory?

    /// Optional content view that is displayed on the trailing edge of the menu value.
    let trailingContent: TrailingContent?

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            menu

            if let footer {
                Divider()

                Text(footer)
                    .styleGuide(.footnote, includeLinePadding: false, includeLineSpacing: false)
                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 16)
        .background(
            isEnabled
                ? SharedAsset.Colors.backgroundSecondary.swiftUIColor
                : SharedAsset.Colors.backgroundSecondaryDisabled.swiftUIColor
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: Private views

    /// The menu that displays the list of options.
    private var menu: some View {
        Menu {
            Picker(selection: $selection) {
                ForEach(options, id: \.hashValue) { option in
                    Text(option.localizedName).tag(option)
                }
            } label: {
                Text("")
            }

            if let additionalMenu {
                additionalMenu
            }
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    if let title {
                        Text(title)
                            .styleGuide(
                                .subheadline,
                                weight: .semibold,
                                includeLinePadding: false,
                                includeLineSpacing: false
                            )
                            .foregroundColor(isEnabled
                                ? SharedAsset.Colors.textSecondary.swiftUIColor
                                : SharedAsset.Colors.buttonFilledDisabledForeground.swiftUIColor
                            )
                            .onSizeChanged { size in
                                titleWidth = size.width
                            }
                    }

                    Text(selection.localizedName)
                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                if let trailingContent {
                    trailingContent
                } else {
                    Asset.Images.chevronDown24.swiftUIImage
                        .imageStyle(.rowIcon)
                }
            }
            .padding(.vertical, 12)
            .transaction { transaction in
                // Prevents any downstream animations from rendering a fade animation
                // on this label.
                transaction.animation = nil
            }
        }
        .styleGuide(.body)
        .foregroundColor(isEnabled
            ? SharedAsset.Colors.textPrimary.swiftUIColor
            : SharedAsset.Colors.buttonFilledDisabledForeground.swiftUIColor
        )
        .frame(minHeight: 64)
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
        .overlay {
            if let titleAccessoryContent {
                titleAccessoryContent
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )
                    .offset(x: titleWidth + 4, y: 12)
            }
        }
    }

    // MARK: Initialization

    /// Initializes a new `BitwardenMenuField`.
    ///
    /// - Parameters:
    ///   - title: The title of the text field.
    ///   - footer: The footer text displayed below the menu field.
    ///   - accessibilityIdentifier: The accessibility identifier for the view.
    ///   - options: The options that the user can choose between.
    ///   - selection: A `Binding` for the currently selected option.
    ///
    init(
        title: String? = nil,
        footer: String? = nil,
        accessibilityIdentifier: String? = nil,
        options: [T],
        selection: Binding<T>
    ) where AdditionalMenu == EmptyView, TitleAccessory == EmptyView, TrailingContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        additionalMenu = nil
        self.footer = footer
        self.options = options
        _selection = selection
        self.title = title
        trailingContent = nil
        titleAccessoryContent = nil
    }

    /// Initializes a new `BitwardenMenuField`.
    ///
    /// - Parameters:
    ///   - title: The title of the text field.
    ///   - footer: The footer text displayed below the menu field.
    ///   - accessibilityIdentifier: The accessibility identifier for the view.
    ///   - options: The options that the user can choose between.
    ///   - selection: A `Binding` for the currently selected option.
    ///   - titleAccessoryContent: Optional title accessory view that is displayed on the trailing edge of the title.
    ///   - trailingContent: Optional content view that is displayed to the right of the menu value.
    ///
    init(
        title: String? = nil,
        footer: String? = nil,
        accessibilityIdentifier: String? = nil,
        options: [T],
        selection: Binding<T>,
        titleAccessoryContent: () -> TitleAccessory,
        trailingContent: () -> TrailingContent
    ) where AdditionalMenu == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        additionalMenu = nil
        self.footer = footer
        self.options = options
        _selection = selection
        self.title = title
        self.titleAccessoryContent = titleAccessoryContent()
        self.trailingContent = trailingContent()
    }

    /// Initializes a new `BitwardenMenuField`.
    ///
    /// - Parameters:
    ///   - title: The title of the text field.
    ///   - footer: The footer text displayed below the menu field.
    ///   - accessibilityIdentifier: The accessibility identifier for the view.
    ///   - options: The options that the user can choose between.
    ///   - selection: A `Binding` for the currently selected option.
    ///   - trailingContent: Optional content view that is displayed to the right of the menu value.
    ///
    init(
        title: String? = nil,
        footer: String? = nil,
        accessibilityIdentifier: String? = nil,
        options: [T],
        selection: Binding<T>,
        trailingContent: () -> TrailingContent
    ) where AdditionalMenu == EmptyView, TitleAccessory == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        additionalMenu = nil
        self.footer = footer
        self.options = options
        _selection = selection
        self.title = title
        titleAccessoryContent = nil
        self.trailingContent = trailingContent()
    }

    /// Initializes a new `BitwardenMenuField`.
    ///
    /// - Parameters:
    ///   - title: The title of the text field.
    ///   - footer: The footer text displayed below the menu field.
    ///   - accessibilityIdentifier: The accessibility identifier for the view.
    ///   - options: The options that the user can choose between.
    ///   - selection: A `Binding` for the currently selected option.
    ///   - titleAccessoryContent: Optional title accessory view that is displayed on the trailing edge of the title.
    ///
    init(
        title: String? = nil,
        footer: String? = nil,
        accessibilityIdentifier: String? = nil,
        options: [T],
        selection: Binding<T>,
        titleAccessoryContent: () -> TitleAccessory
    ) where AdditionalMenu == EmptyView, TrailingContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        additionalMenu = nil
        self.footer = footer
        self.options = options
        _selection = selection
        self.title = title
        self.titleAccessoryContent = titleAccessoryContent()
        trailingContent = nil
    }

    /// Initializes a new `BitwardenMenuField`.
    ///
    /// - Parameters:
    ///   - title: The title of the text field.
    ///   - footer: The footer text displayed below the menu field.
    ///   - accessibilityIdentifier: The accessibility identifier for the view.
    ///   - options: The options that the user can choose between.
    ///   - selection: A `Binding` for the currently selected option.
    ///   - additionalMenu: Additional menu options to display at the bottom of the menu.
    ///
    @_disfavoredOverload
    init(
        title: String? = nil,
        footer: String? = nil,
        accessibilityIdentifier: String? = nil,
        options: [T],
        selection: Binding<T>,
        @ViewBuilder additionalMenu: () -> AdditionalMenu
    ) where TrailingContent == EmptyView, TitleAccessory == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.additionalMenu = additionalMenu()
        self.footer = footer
        self.options = options
        _selection = selection
        self.title = title
        titleAccessoryContent = nil
        trailingContent = nil
    }
}

// MARK: Previews

#if DEBUG
private enum MenuPreviewOptions: CaseIterable, Menuable {
    case bear, bird, dog

    var localizedName: String {
        switch self {
        case .bear: return "🧸"
        case .bird: return "🪿"
        case .dog: return "🐕"
        }
    }
}

#Preview("CipherType") {
    VStack {
        BitwardenMenuField(
            title: "Animals",
            options: MenuPreviewOptions.allCases,
            selection: .constant(.dog)
        )
        .padding()

        BitwardenMenuField(
            title: "Animals",
            options: MenuPreviewOptions.allCases,
            selection: .constant(.dog)
        )
        .disabled(true)
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Trailing Button") {
    Group {
        BitwardenMenuField(
            title: "Animals",
            options: MenuPreviewOptions.allCases,
            selection: .constant(.dog),
            trailingContent: {
                Button {} label: {
                    Asset.Images.camera16.swiftUIImage
                }
                .buttonStyle(.accessory)
            }
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Footer") {
    Group {
        BitwardenMenuField(
            title: "Animals",
            footer: "Select your favorite animal",
            options: MenuPreviewOptions.allCases,
            selection: .constant(.dog)
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Addititional Menu") {
    Group {
        BitwardenMenuField(
            title: "Animals",
            options: MenuPreviewOptions.allCases,
            selection: .constant(.dog),
            additionalMenu: {
                Button("Add an animal") {}
            }
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
#endif
