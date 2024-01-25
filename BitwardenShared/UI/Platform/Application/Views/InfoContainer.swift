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
            .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .styleGuide(.callout)
            .padding(16)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Asset.Colors.primaryBitwarden.swiftUIColor)
            }
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
}

#Preview {
    InfoContainer {
        HStack {
            Image(systemName: "info.circle")
            Text("Info")
        }
    }
}
