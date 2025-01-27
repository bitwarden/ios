import SwiftUI

// MARK: - SectionHeaderView

/// A section header.
///
struct SectionHeaderView: View {
    // MARK: Type

    // TODO: PM-17020 - Remove DesignVersion after app has updated all section headers to v2.
    /// An enum that represents two different design versions of the section header.
    ///
    enum DesignVersion {
        case v1, v2 // swiftlint:disable:this identifier_name

        /// The leading padding to apply to the header text.
        var leadingPadding: CGFloat {
            switch self {
            case .v1: 0
            case .v2: 12
            }
        }

        /// The font to apply to the header text.
        var styleGuideFont: StyleGuideFont {
            switch self {
            case .v1: .footnote
            case .v2: .caption1
            }
        }

        /// The font weight to apply to the header text.
        var fontWeight: SwiftUI.Font.Weight {
            switch self {
            case .v1: .regular
            case .v2: .bold
            }
        }
    }

    // MARK: Properties

    /// The version of the header to use.
    let designVersion: DesignVersion

    /// The section title.
    let title: String

    // MARK: View

    var body: some View {
        Text(title)
            .styleGuide(designVersion.styleGuideFont, weight: designVersion.fontWeight)
            .accessibilityAddTraits(.isHeader)
            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
            .textCase(.uppercase)
            .padding(.leading, designVersion.leadingPadding)
    }

    // MARK: Initialization

    /// Initializes a new section header.
    ///
    /// - Parameters:
    ///   - title: The section title.
    ///
    init(_ title: String, designVersion: DesignVersion = .v1) {
        self.designVersion = designVersion
        self.title = title
    }
}

// MARK: Previews

#Preview {
    SectionHeaderView("Section header")

    SectionHeaderView("Section header", designVersion: .v2)
}
