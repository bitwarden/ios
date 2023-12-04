import SwiftUI

/// A view to display Sections in a list.
///
struct VaultItemSectionView<Content>: View where Content: View {
    /// The title of the section
    let title: String

    /// The section content.
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
        }
    }
}
