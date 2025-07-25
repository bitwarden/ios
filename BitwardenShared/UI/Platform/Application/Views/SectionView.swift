import BitwardenResources
import SwiftUI

// MARK: - SectionView

/// A section view.
///
struct SectionView<Content: View>: View {
    // MARK: Properties

    /// Content displayed below section header view.
    let content: Content

    /// The spacing of the content.
    let contentSpacing: CGFloat

    /// The section header title.
    let title: String

    /// The spacing between title and content.
    let titleSpacing: CGFloat

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: titleSpacing) {
            SectionHeaderView(title)

            VStack(alignment: .leading, spacing: contentSpacing) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Initialization

    /// Initializes a new section view.
    ///
    /// - Parameters:
    ///   - title: The section header title.
    ///   - titleSpacing: The spacing between title and content.
    ///   - content: The content displayed below the section title.
    ///   - contentSpacing: The spacing of content items.
    ///
    init(
        _ title: String,
        titleSpacing: CGFloat = 8,
        contentSpacing: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.titleSpacing = titleSpacing
        self.contentSpacing = contentSpacing
        self.content = content()
    }
}

// MARK: Previews

#if DEBUG
struct SectionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SectionView("Section View") {
                BitwardenTextField(title: Localizations.name, text: .constant("name"))
            }
        }
        .padding(16)
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
    }
}
#endif
