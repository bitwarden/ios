import SwiftUI

/// A view that displays a `VaultListSection`.
///
struct VaultListSectionView<Content: View>: View {
    // MARK: Properties

    /// The section to display.
    let section: VaultListSection

    /// A closure that returns the content for a `VaultListItem` in the section.
    @ViewBuilder var itemContent: (VaultListItem) -> Content

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeaderView(section.name)
                Spacer()
                SectionHeaderView(String(section.items.count))
            }

            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(section.items) { item in
                    itemContent(item)
                }
            }
            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
