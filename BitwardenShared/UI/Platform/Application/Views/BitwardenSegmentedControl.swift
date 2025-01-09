import SwiftUI

// MARK: BitwardenSegmentedControl

/// A custom segmented control.
///
struct BitwardenSegmentedControl<T: Menuable & Identifiable>: View {
    // MARK: Properties

    /// A closure that returns whether a selection should be disabled from user input.
    let isSelectionDisabled: (T) -> Bool

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
                    segmentView(
                        title: selection.localizedName,
                        isDisabled: isSelectionDisabled(selection),
                        isSelected: selection == self.selection
                    )
                    .matchedGeometryEffect(id: selection, in: segmentedControl)
                }
                .accessibilityIdentifier(selection.accessibilityId)
                .disabled(isSelectionDisabled(selection))
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

    // MARK: Initialization

    /// Initialize a `BitwardenSegmentedControl`.
    ///
    /// - Parameters:
    ///   - isSelectionDisabled: A closure that returns whether a selection should be disabled from user input.
    ///   - selection: A binding to the currently selected segment.
    ///   - selections: The list of selections to show in the control.
    ///
    init(
        isSelectionDisabled: @escaping (T) -> Bool = { _ in false },
        selection: Binding<T>,
        selections: [T]
    ) {
        self.isSelectionDisabled = isSelectionDisabled
        _selection = selection
        self.selections = selections
    }

    // MARK: Private

    /// Returns the foreground color for a segment.
    ///
    /// - Parameters:
    ///   - isDisabled: Whether the segment is disabled.
    ///   - isSelected: Whether the segment is selected.
    ///
    private func segmentForegroundColor(isDisabled: Bool, isSelected: Bool) -> Color {
        guard !isDisabled else { return Asset.Colors.buttonFilledDisabledForeground.swiftUIColor }
        return isSelected ?
            Asset.Colors.textInteraction.swiftUIColor :
            Asset.Colors.textSecondary.swiftUIColor
    }

    /// Returns a view for a single segment within the segmented control.
    ///
    /// - Parameters:
    ///   - title: The title of the segment.
    ///   - isDisabled: Whether the segment is disabled.
    ///   - isSelected: Whether the segment is selected.
    ///
    private func segmentView(title: String, isDisabled: Bool, isSelected: Bool) -> some View {
        Text(title)
            .styleGuide(.callout, weight: .semibold)
            .frame(maxWidth: .infinity)
            .foregroundStyle(segmentForegroundColor(isDisabled: isDisabled, isSelected: isSelected))
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
