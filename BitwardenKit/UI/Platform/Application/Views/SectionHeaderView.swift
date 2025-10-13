import BitwardenResources
import SwiftUI

// MARK: - SectionHeaderView

/// A section header.
///
public struct SectionHeaderView: View {
    // MARK: Properties

    /// The section title.
    let title: String

    // MARK: View

    public var body: some View {
        Text(title)
            .styleGuide(.caption1, weight: .bold)
            .accessibilityAddTraits(.isHeader)
            .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
            .textCase(.uppercase)
            .padding(.leading, 12)
    }

    // MARK: Initialization

    /// Initializes a new section header.
    ///
    /// - Parameters:
    ///   - title: The section title.
    ///
    public init(_ title: String) {
        self.title = title
    }
}

// MARK: Previews

#Preview {
    SectionHeaderView("Section header")
}
