import BitwardenResources
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
                let isSelected = self.selection.id == selection.id
                Button {
                    // Don't update the selection if this segment is already selected.
                    guard !isSelected else { return }
                    self.selection = selection
                } label: {
                    Text(selection.localizedName)
                        .styleGuide(.callout, weight: .semibold)
                }
                .accessibility(if: isSelected, addTraits: .isSelected)
                .accessibilityIdentifier(selection.accessibilityId)
                .buttonStyle(SegmentButtonStyle(isSelected: isSelected))
                .disabled(isSelectionDisabled(selection))
                .matchedGeometryEffect(id: selection, in: segmentedControl)
            }
        }
        .background(
            Capsule()
                .strokeBorder(SharedAsset.Colors.strokeSegmentedNavigation.swiftUIColor, lineWidth: 0.5)
                .background(Capsule().fill(SharedAsset.Colors.backgroundSecondary.swiftUIColor))
                .padding(2)
                .matchedGeometryEffect(id: selection, in: segmentedControl, isSource: false)
        )
        .animation(.default, value: selection)
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
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
}

// MARK: - SegmentButtonStyle

/// A `ButtonStyle` for displaying a segment within the `BitwardenSegmentedControl`.
///
private struct SegmentButtonStyle: ButtonStyle {
    // MARK: Properties

    @Environment(\.isEnabled) var isEnabled: Bool

    /// Whether the segment is selected.
    let isSelected: Bool

    /// The color of the foreground elements in the button.
    var foregroundColor: Color {
        guard isEnabled else { return SharedAsset.Colors.buttonFilledDisabledForeground.swiftUIColor }
        return isSelected
            ? SharedAsset.Colors.textInteraction.swiftUIColor
            : SharedAsset.Colors.textSecondary.swiftUIColor
    }

    // MARK: ButtonStyle

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .foregroundStyle(foregroundColor)
            .padding(.vertical, 8)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .opacity(configuration.isPressed && !isSelected ? 0.5 : 1)
            .contentShape(Capsule())
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
