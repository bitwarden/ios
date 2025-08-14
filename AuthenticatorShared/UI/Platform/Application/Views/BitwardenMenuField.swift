import BitwardenResources
import SwiftUI

// MARK: - Menuable

/// A protocol that defines an object that can be represented and selected in
/// a `BitwardenMenuField`.
protocol Menuable: Equatable, Hashable {
    ///  The custom localizable title value for this default case, defaults to  `Default`.
    static var defaultValueLocalizedName: String { get }

    /// A localized name value. This value is displayed in the Menu when the user
    /// is making a selection between multiple options.
    var localizedName: String { get }
}

extension Menuable {
    static var defaultValueLocalizedName: String {
        Localizations.default
    }
}

// MARK: - BitwardenMenuField

/// A standard input field that allows the user to select between a predefined set of
/// options. This view is identical to `BitwardenTextField`, but uses a `Menu`
/// instead of a `TextField` as the input mechanism.
///
struct BitwardenMenuField<T, TrailingContent: View>: View where T: Menuable {
    // MARK: Properties

    /// The selection chosen from the menu.
    @Binding var selection: T

    /// The accessibility identifier for the view.
    let accessibilityIdentifier: String?

    /// The options displayed in the menu.
    let options: [T]

    /// The footer text displayed below the menu field.
    let footer: String?

    /// The title of the menu field.
    let title: String?

    /// Optional content view that is displayed on the trailing edge of the menu value.
    let trailingContent: TrailingContent?

    // MARK: View

    var body: some View {
        BitwardenField(title: title, footer: footer) {
            menu
        } accessoryContent: {
            if let trailingContent {
                trailingContent
            }
        }
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
            .accessibilityIdentifier(accessibilityIdentifier ?? "")
        } label: {
            HStack {
                Text(selection.localizedName)
                Spacer()
            }
            .contentShape(Rectangle())
            .transaction { transaction in
                // Prevents any downstream animations from rendering a fade animation
                // on this label.
                transaction.animation = nil
            }
        }
        .styleGuide(.body)
        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
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
    ) where TrailingContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.footer = footer
        self.options = options
        _selection = selection
        self.title = title
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
    ///   - trailingContent: Optional content view that is displayed to the right of the menu value.
    ///
    init(
        title: String? = nil,
        footer: String? = nil,
        accessibilityIdentifier: String? = nil,
        options: [T],
        selection: Binding<T>,
        trailingContent: () -> TrailingContent
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.footer = footer
        self.options = options
        _selection = selection
        self.title = title
        self.trailingContent = trailingContent()
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
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Trailing Button") {
    Group {
        BitwardenMenuField(
            title: "Animals",
            options: MenuPreviewOptions.allCases,
            selection: .constant(.dog)
        ) {
            Button {} label: {
                Asset.Images.camera.swiftUIImage
            }
            .buttonStyle(.accessory)
        }
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
#endif
