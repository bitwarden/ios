import BitwardenKit
import BitwardenResources
import SwiftUI

/// A view that displays a `VaultListSection`.
///
struct VaultListSectionView<Content: View>: View {
    // MARK: Properties

    /// An optional binding driving the section's expanded / collapsed state. When provided, the
    /// section renders a collapsible `ExpandableHeaderView` whose state is driven by this binding;
    /// when `nil`, the section renders a static, non-collapsible header.
    let isExpanded: Binding<Bool>?

    /// The section to display.
    let section: VaultListSection

    /// Whether the items count should be shown.
    let showCount: Bool

    /// A closure that returns the content for a `VaultListItem` in the section.
    @ViewBuilder var itemContent: (VaultListItem) -> Content

    // MARK: View

    var body: some View {
        if let isExpanded {
            ExpandableHeaderView(
                title: section.name,
                count: section.items.count,
                buttonAccessibilityIdentifier: "SectionExpandButton_\(section.id)",
                isExpanded: isExpanded,
            ) {
                itemsContent
            }
        } else {
            VStack(alignment: .leading, spacing: 7) {
                if showCount {
                    SectionHeaderView("\(section.name) (\(section.items.count))")
                        .accessibilityLabel("\(section.name), \(Localizations.xItems(section.items.count))")
                } else {
                    SectionHeaderView(section.name)
                }

                itemsContent
            }
        }
    }

    // MARK: Private views

    /// The list of item rows displayed within the section.
    private var itemsContent: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(section.items) { item in
                itemContent(item)
            }
        }
        .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Initializers

    /// Initializes a `VaultListSectionView`
    /// - Parameters:
    ///   - section: The section with the values.
    ///   - showCount: Whether the items count should be shown.
    ///   - isExpanded: An optional binding driving the section's expanded state. When provided, the
    ///     section renders a collapsible `ExpandableHeaderView`; when `nil`, a static header is used.
    ///   - itemContent: The content for each item.
    init(
        section: VaultListSection,
        showCount: Bool = true,
        isExpanded: Binding<Bool>? = nil,
        itemContent: @escaping (VaultListItem) -> Content,
    ) {
        self.section = section
        self.showCount = showCount
        self.isExpanded = isExpanded
        self.itemContent = itemContent
    }
}
