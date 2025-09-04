import BitwardenResources
import SwiftUI

// MARK: - BitwardenMenuFooterTextField

/// A text view for the footer on BitwardenMenu
///
struct BitwardenMenuFooterTextField: View {
    
    /// The content of the text view.
    private let content: Text
    
    /// The bottom padding of the text view.
    private let topPadding: CGFloat
    
    /// The bottom padding of the text view.
    private let bottomPadding: CGFloat

    init(_ content: Text, topPadding: CGFloat = 0, bottomPadding: CGFloat = 12) {
        self.content = content
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
    }
    
    init(_ title: LocalizedStringKey, topPadding: CGFloat = 0, bottomPadding: CGFloat = 12) {
        content = Text(title)
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
    }
    
    init(_ title: String, topPadding: CGFloat = 0, bottomPadding: CGFloat = 12) {
        content = Text(title)
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
    }

    // MARK: View
    var body: some View {
        content
            .styleGuide(.footnote, includeLinePadding: false, includeLineSpacing: false)
            .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
            .multilineTextAlignment(.leading)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
    }
}
