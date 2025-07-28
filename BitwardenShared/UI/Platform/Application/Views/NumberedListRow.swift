import BitwardenResources
import SwiftUI

/// A view that displays a single row within a `NumberedList`.
///
struct NumberedListRow: View {
    // MARK: Properties

    /// The title to display in the row.
    let title: String

    /// An optional subtitle to display in the row.
    let subtitle: String?

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LocalizedStringKey(title))
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

            if let subtitle {
                Text(LocalizedStringKey(subtitle))
                    .styleGuide(.subheadline)
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
            }
        }
        .padding(.vertical, 12)
        .padding(.trailing, 16) // Leading padding is handled by `NumberedList`.
    }

    // MARK: Initialization

    /// Initializes a `NumberedListRow`.
    ///
    /// - Parameters:
    ///   - title: The title to display in the row.
    ///   - subtitle: An optional subtitle to display in the row.
    ///
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    NumberedList {
        NumberedListRow(title: "Apple 🍎")
        NumberedListRow(title: "Banana 🍌")
        NumberedListRow(title: "Grapes 🍇")
    }
}
#endif
