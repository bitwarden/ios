import SwiftUI

// MARK: - SectionView

/// A section view.
///
struct SectionView<Content: View>: View {
    // MARK: Properties

    /// The section header title.
    let title: String

    /// Content displayed below section header view.
    let content: Content

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title)

            content
        }
    }

    // MARK: Initialization

    /// Initializes a new section view.
    ///
    /// - Parameters:
    ///   - title: The section header title.
    ///   - content: The content displayed below the section title.
    ///
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
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
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
    }
}
#endif
