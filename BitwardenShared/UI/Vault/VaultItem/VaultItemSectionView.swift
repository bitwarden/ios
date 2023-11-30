import SwiftUI

/// A view to display Sections in a list.
///
struct VaultItemSectionView<Content>: View where Content: View {
    /// The spacing of the content.
    var contentSpacing: CGFloat = 16

    /// The spacing between title and content.
    var titleSpacing: CGFloat = 16

    /// The title of the section
    let title: String

    /// The section content.
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: titleSpacing) {
            Text(title.uppercased())
                .font(.footnote)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
            VStack(alignment: .leading, spacing: contentSpacing) {
                content()
            }
        }
    }
}
