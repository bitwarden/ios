import SwiftUI

// MARK: - SectionHeaderView

struct SectionHeaderView: View {
    // MARK: Properties

    /// The section title.
    let title: String

    // MARK: View

    var body: some View {
        Text(title)
            .accessibilityAddTraits(.isHeader)
            .font(.styleGuide(.footnote))
            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
            .textCase(.uppercase)
    }

    // MARK: Initialization

    /// Initializes a new section header.
    ///
    /// - Parameters:
    ///   - title: The section title.
    ///
    init(_ title: String) {
        self.title = title
    }
}

// MARK: Previews

#Preview {
    SectionHeaderView("Section header")
}
