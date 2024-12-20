import SwiftUI

// MARK: BitwardenSegmentedControl

/// A custom segmented control.
///
struct BitwardenSegmentedControl<T: Menuable & Identifiable>: View {
    // MARK: Properties

    /// The currently selected segment.
    @Binding var selection: T

    /// The list of selections to show in the control.
    let selections: [T]

    // MARK: Private Properties

    /// A namespace for coordinating the selected segment animation.
    @Namespace private var segmentedControl

    // MARK: View

    var body: some View {
        HStack(spacing: 0) {
            ForEach(selections) { selection in
                Button {
                    self.selection = selection
                } label: {
                    segmentView(title: selection.localizedName, isSelected: selection == self.selection)
                        .matchedGeometryEffect(id: selection, in: segmentedControl)
                }
            }
        }
        .background(
            Capsule()
                .strokeBorder(Asset.Colors.strokeSegmentedNavigation.swiftUIColor, lineWidth: 0.5)
                .background(Capsule().fill(Asset.Colors.backgroundSecondary.swiftUIColor))
                .padding(2)
                .matchedGeometryEffect(id: selection, in: segmentedControl, isSource: false)
        )
        .animation(.default, value: selection)
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
        .clipShape(Capsule())
    }

    /// Returns a view for a single segment within the segmented control.
    ///
    /// - Parameters:
    ///   - title: The title of the segment.
    ///   - isSelected: Whether the segment is selected.
    ///
    func segmentView(title: String, isSelected: Bool) -> some View {
        Text(title)
            .styleGuide(.callout, weight: .semibold)
            .frame(maxWidth: .infinity)
            .foregroundStyle(
                isSelected ?
                    Asset.Colors.textInteraction.swiftUIColor :
                    Asset.Colors.textSecondary.swiftUIColor
            )
            .padding(.vertical, 8)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17, *)
#Preview {
    @Previewable @SwiftUI.State var selection = GeneratorType.password

    BitwardenSegmentedControl(
        selection: $selection,
        selections: GeneratorType.allCases
    )
    .padding()
}
#endif
