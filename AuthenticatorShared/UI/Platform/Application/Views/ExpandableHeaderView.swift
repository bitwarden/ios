import BitwardenResources
import SwiftUI

// MARK: - ExpandableHeaderView

/// A wrapper around some content which can be expanded to show the content or collapsed to hide it.
///
struct ExpandableHeaderView<Content: View>: View {
    // MARK: Properties

    /// The accessibility identifier for the button to expand or collapse the content.
    let buttonAccessibilityIdentifier: String

    /// The content that is shown when the section is expanded or hidden otherwise.
    let content: Content

    /// A var to determine if the content in the section is expanded or collapsed.
    @State private var isExpanded: Bool = true

    /// A value indicating whether the expandable content is currently enabled or disabled.
    @Environment(\.isEnabled) var isEnabled: Bool

    /// The title of the Header button used to expand or collapse the content.
    let title: String

    /// The count of items on the Content
    let count: Int

    // MARK: View

    var body: some View {
        VStack(spacing: 8) {
            expandButton

            if isExpanded {
                content
            }
        }
    }

    // MARK: Private

    /// The button to expand or collapse the content.
    @ViewBuilder private var expandButton: some View {
        Button {
            withAnimation {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                SectionHeaderView("\(title) (\(count))")

                Asset.Images.chevronDown.swiftUIImage
                    .imageStyle(.accessoryIcon(scaleWithFont: true))
                    .rotationEffect(isExpanded ? Angle(degrees: 180) : .zero)
            }
            .multilineTextAlignment(.leading)
            .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
        }
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier(buttonAccessibilityIdentifier)
        .padding(.leading, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Initialization

    /// Initialize an `ExpandableContent`.
    ///
    /// - Parameters:
    ///   - title: The title of the button used to expand or collapse the content.
    ///   - isExpanded: A binding to determine if the content in the section is expanded or collapsed.
    ///   - buttonAccessibilityIdentifier: The accessibility identifier for the button to expand or
    ///     collapse the content.
    ///   - content: The content that is shown when the section is expanded or hidden otherwise.
    init(
        title: String,
        count: Int,
        buttonAccessibilityIdentifier: String = "ExpandSectionButton",
        @ViewBuilder content: () -> Content
    ) {
        self.buttonAccessibilityIdentifier = buttonAccessibilityIdentifier
        self.content = content()
        self.title = title
        self.count = count
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17, *)
#Preview {
    @Previewable @SwiftUI.State var isExpanded = false

    VStack {
        ExpandableHeaderView(title: Localizations.localCodes, count: 3) {
            BitwardenTextValueField(value: "Option 1")
            BitwardenTextValueField(value: "Option 2")
            BitwardenTextValueField(value: "Option 3")
        }
    }
    .padding()
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Asset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
