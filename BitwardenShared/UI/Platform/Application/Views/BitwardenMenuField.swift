import SwiftUI

// MARK: - Menuable

/// A protocol that defines an object that can be represented and selected in
/// a `BitwardenMenuField`.
protocol Menuable: Equatable, Hashable {
    /// A localized name value. This value is displayed in the Menu when the user
    /// is making a selection between multiple options.
    var localizedName: String { get }
}

// MARK: - BitwardenMenuField

/// A standard input field that allows the user to select between a predefined set of
/// options. This view is identical to `BitwardenTextField`, but uses a `Menu`
/// instead of a `TextField` as the input mechanism.
///
struct BitwardenMenuField<T>: View where T: Menuable {
    // MARK: Properties

    /// The selection chosen from the menu.
    @Binding var selection: T

    /// The options displayed in the menu.
    let options: [T]

    /// The title of the menu field.
    let title: String?

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            menuFieldTitle
            menu
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
        } label: {
            HStack {
                Text(selection.localizedName)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .font(.styleGuide(.body))
        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
        .id(title)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// The title of the menu field.
    @ViewBuilder private var menuFieldTitle: some View {
        if let title {
            Text(title)
                .font(.styleGuide(.subheadline))
                .bold()
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
        }
    }

    // MARK: Initialization

    /// Initializes a new `BitwardenMenuField`.
    ///
    /// - Parameters:
    ///   - title: The title of the text field.
    ///   - options: The options that the user can choose between.
    ///   - selection: A `Binding` for the currently selected option.
    ///
    init(
        title: String? = nil,
        options: [T],
        selection: Binding<T>
    ) {
        self.options = options
        _selection = selection
        self.title = title
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

struct BitwardenMenuField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BitwardenMenuField(
                title: "Animals",
                options: MenuPreviewOptions.allCases,
                selection: .constant(.dog)
            )
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("CipherType")
    }
}
#endif
