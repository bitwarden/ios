import SwiftUI

// MARK: - SettingsMenuField

/// A standard input field that allows the user to select between a predefined set of
/// options.
///
struct SettingsMenuField<T>: View where T: Menuable {
    // MARK: Properties

    /// Whether the menu field should have a bottom divider.
    let hasDivider: Bool

    /// The selection chosen from the menu.
    @Binding var selection: T

    /// The options displayed in the menu.
    let options: [T]

    /// The title of the menu field.
    let title: String

    // MARK: View

    var body: some View {
        VStack(spacing: 0) {
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
                    Text(title)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                        .padding(.vertical, 19)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    Text(selection.localizedName)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                }
            }
            .styleGuide(.body)

            .id(title)
            .padding(.horizontal, 16)

            if hasDivider {
                Divider()
                    .padding(.leading, 16)
            }
        }
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
    }

    /// Initializes a new `SettingsMenuField`.
    ///
    /// - Parameters:
    ///   - title: The title of the menu field.
    ///   - options: The options that the user can choose between.
    ///   - hasDivider: Whether the menu field should have a bottom divider.
    ///   - selection: A `Binding` for the currently selected option.
    ///
    init(
        title: String,
        options: [T],
        hasDivider: Bool = true,
        selection: Binding<T>
    ) {
        self.hasDivider = hasDivider
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

#Preview {
    Group {
        VStack(spacing: 0) {
            SettingsMenuField(
                title: "Bear",
                options: MenuPreviewOptions.allCases,
                selection: .constant(.bear)
            )
            SettingsMenuField(
                title: "Dog",
                options: MenuPreviewOptions.allCases,
                hasDivider: false,
                selection: .constant(.dog)
            )
        }
        .padding(8)
    }
    .background(Color(.systemGroupedBackground))
}
#endif
