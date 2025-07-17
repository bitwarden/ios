import BitwardenResources
import SwiftUI

/// A view that displays a `VaultListSection`.
///
struct VaultListSectionView<Content: View>: View {
    // MARK: Properties

    /// The section to display.
    let section: VaultListSection

    /// Whether the items count should be shown.
    let showCount: Bool

    /// A closure that returns the content for a `VaultListItem` in the section.
    @ViewBuilder var itemContent: (VaultListItem) -> Content

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if showCount {
                SectionHeaderView("\(section.name) (\(section.items.count))")
                    .accessibilityLabel("\(section.name), \(Localizations.xItems(section.items.count))")
            } else {
                SectionHeaderView(section.name)
            }

            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(section.items) { item in
                    itemContent(item)
                }
            }
            .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: Initializers

    /// Initializes a `VaultListSectionView`
    /// - Parameters:
    ///   - section: The section with the values.
    ///   - showCount: Whether the items count should be shown.
    ///   - itemContent: The content for each item.
    init(section: VaultListSection, showCount: Bool = true, itemContent: @escaping (VaultListItem) -> Content) {
        self.section = section
        self.showCount = showCount
        self.itemContent = itemContent
    }
}
