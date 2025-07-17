import BitwardenResources
import SwiftUI

// MARK: - ExpandableContent

/// A wrapper around some content which can be expanded to show the content or collapsed to hide it.
///
struct ExpandableContent<Content: View>: View {
    // MARK: Properties

    /// The accessibility identifier for the button to expand or collapse the content.
    let buttonAccessibilityIdentifier: String

    /// The content that is shown when the section is expanded or hidden otherwise.
    let content: Content

    /// A binding to determine if the content in the section is expanded or collapsed.
    @Binding var isExpanded: Bool

    /// A value indicating whether the expandable content is currently enabled or disabled.
    @Environment(\.isEnabled) var isEnabled: Bool

    /// The title of the button used to expand or collapse the content.
    let title: String

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
                Text(title)
                    .styleGuide(.callout, weight: .semibold)

                Asset.Images.chevronDown16.swiftUIImage
                    .imageStyle(.accessoryIcon16(scaleWithFont: true))
                    .rotationEffect(isExpanded ? Angle(degrees: 180) : .zero)
            }
            .multilineTextAlignment(.leading)
            .foregroundStyle(
                isEnabled
                    ? SharedAsset.Colors.textInteraction.swiftUIColor
                    : SharedAsset.Colors.textDisabled.swiftUIColor
            )
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
        isExpanded: Binding<Bool>,
        buttonAccessibilityIdentifier: String = "ExpandSectionButton",
        @ViewBuilder content: () -> Content
    ) {
        self.buttonAccessibilityIdentifier = buttonAccessibilityIdentifier
        self.content = content()
        _isExpanded = isExpanded
        self.title = title
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17, *)
#Preview {
    @Previewable @SwiftUI.State var isExpanded = false

    VStack {
        ExpandableContent(title: Localizations.additionalOptions, isExpanded: $isExpanded) {
            BitwardenTextValueField(value: "Option 1")
            BitwardenTextValueField(value: "Option 2")
            BitwardenTextValueField(value: "Option 3")
        }
    }
    .padding()
    .frame(maxHeight: .infinity, alignment: .top)
    .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
