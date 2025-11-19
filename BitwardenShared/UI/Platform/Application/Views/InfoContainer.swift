import BitwardenResources
import SwiftUI

/// An informational container that displays some content surrounded by a blue border.
///
struct InfoContainer<Content: View>: View {
    // MARK: Properties

    /// The content to display in the container.
    let content: Content

    // MARK: View

    var body: some View {
        content
            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .styleGuide(.callout)
            .padding(16)
            .background(SharedAsset.Colors.backgroundTertiary.swiftUIColor)
            .cornerRadius(8)
    }

    // MARK: Initialization

    /// Initialize a new info container.
    ///
    /// - Parameter content: The content to display in the container.
    ///
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    /// Initialize a new info container that displays text content.
    ///
    /// - Parameter text: The text message to display in the container.
    ///
    init(_ text: String) where Content == Text {
        content = Text(text)
    }
}

// MARK: - Previews

#Preview {
    InfoContainer("Hello!")
        .padding()
}

#Preview {
    InfoContainer {
        HStack {
            Image(systemName: "info.circle")
            Text("Info")
        }
    }
    .padding()
}
