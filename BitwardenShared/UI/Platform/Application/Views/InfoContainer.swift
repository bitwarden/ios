import BitwardenKit
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

    /// Initialize a new info container that displays an icon and text content.
    ///
    /// - Parameters:
    ///   - text: The text message to display in the container.
    ///   - icon: The icon image asset to display alongside the text.
    ///
    init(text: String, icon: SharedImageAsset) where Content == AnyView {
        content = AnyView(
            HStack(alignment: .center) {
                Image(decorative: icon)
                    .resizable()
                    .scaledToFit()
                    .imageStyle(.accessoryIcon16(scaleWithFont: true))

                Text(text)
            },
        )
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

#Preview {
    InfoContainer(text: "Hello!", icon: SharedAsset.Icons.archive24)
        .padding()
}
