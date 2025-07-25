import BitwardenResources
import SwiftUI

// MARK: - SearchNoResultsView

/// A view that displays the no search results image and text.
///
struct SearchNoResultsView<Content: View>: View {
    // MARK: Properties

    /// An optional view to display at the top of the scroll view above the no results image and text.
    var headerView: Content?

    // MARK: View

    var body: some View {
        GeometryReader { reader in
            ScrollView {
                VStack(spacing: 0) {
                    if let headerView {
                        headerView
                    }

                    VStack(spacing: 35) {
                        Image(decorative: Asset.Images.search24)
                            .resizable()
                            .frame(width: 74, height: 74)
                            .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)

                        Text(Localizations.thereAreNoItemsThatMatchTheSearch)
                            .multilineTextAlignment(.center)
                            .styleGuide(.callout)
                            .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    }
                    .accessibilityIdentifier("NoSearchResultsLabel")
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: reader.size.height, maxHeight: .infinity)
                }
            }
        }
        .background(Color(asset: SharedAsset.Colors.backgroundPrimary))
    }

    // MARK: Initialization

    /// Initialize a `SearchNoResultsView`.
    ///
    init() where Content == EmptyView {
        headerView = nil
    }

    /// Initialize a `SearchNoResultsView` with a header view.
    ///
    /// - Parameter headerView: An optional view to display at the top of the scroll view above the
    ///     no results image and text.
    ///
    init(headerView: () -> Content) {
        self.headerView = headerView()
    }
}

// MARK: - Previews

#Preview("No Results") {
    SearchNoResultsView()
}

#Preview("No Results With Header") {
    SearchNoResultsView {
        Text("Optional header text!")
    }
}
