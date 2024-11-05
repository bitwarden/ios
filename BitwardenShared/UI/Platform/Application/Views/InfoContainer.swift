import SwiftUI

/// An informational container that displays some content surrounded by a blue border.
///
struct InfoContainer<Content: View>: View {
    // MARK: Properties

    /// The content to display in the container.
    let content: Content

    /// Returns an `Alignment` for the content's frame alignment based on the environment's
    /// multiline text alignment.
    var contentAlignment: Alignment {
        switch textAlignment {
        case .center:
            Alignment.center
        case .leading:
            Alignment.leading
        case .trailing:
            Alignment.trailing
        }
    }

    /// The text alignment to apply to the view.
    let textAlignment: TextAlignment

    // MARK: View

    var body: some View {
        content
            .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
            .frame(maxWidth: .infinity, alignment: contentAlignment)
            .multilineTextAlignment(textAlignment)
            .styleGuide(.callout)
            .padding(16)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Asset.Colors.strokeBorder.swiftUIColor)
            }
    }

    // MARK: Initialization

    /// Initialize a new info container.
    ///
    /// - Parameters:
    ///   - textAlignment: The text alignment to apply to the view.
    ///   - content: The content to display in the container.
    ///
    init(
        textAlignment: TextAlignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.textAlignment = textAlignment
    }

    /// Initialize a new info container that displays text content.
    ///
    /// - Parameters:
    ///   - text: The text message to display in the container.
    ///   - textAlignment: The text alignment to apply to the view.
    ///
    init(
        _ text: String,
        textAlignment: TextAlignment = .center
    ) where Content == Text {
        content = Text(text)
        self.textAlignment = textAlignment
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
