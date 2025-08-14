import BitwardenResources
import SwiftUI

// MARK: - SendItemAccessCountStepper

/// A view containing the stepper component for a send's maximum access count.
///
struct SendItemAccessCountStepper: View {
    // MARK: Properties

    /// The number of times the send has been accessed.
    let currentAccessCount: Int?

    /// Whether the maximum access count info text should be displayed in the footer.
    let displayInfoText: Bool

    /// A binding for changing the maximum access account for the send in the stepper.
    @Binding var maximumAccessCount: Int

    // MARK: View

    var body: some View {
        ContentBlock(dividerLeadingPadding: 16) {
            BitwardenStepper(
                value: $maximumAccessCount,
                in: 0 ... Int.max,
                allowTextFieldInput: true,
                textFieldAccessibilityIdentifier: "MaxAccessCountTextField"
            ) {
                Text(Localizations.maximumAccessCount)
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
            } footer: {
                VStack(alignment: .leading, spacing: 2) {
                    if displayInfoText {
                        Text(Localizations.maximumAccessCountInfo)
                            .styleGuide(.footnote)
                            .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                    }

                    if let currentAccessCount, maximumAccessCount > 0 {
                        // Wrap these texts in a group so that the style guide can be set on
                        // both of them at once.
                        Group {
                            Text("\(Localizations.currentAccessCount): ")
                                + Text("\(currentAccessCount)")
                                .fontWeight(.bold)
                        }
                        .styleGuide(.footnote)
                        .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                    }
                }
            }
            .accessibilityIdentifier("SendMaxAccessCountEntry")
        }
    }

    // MARK: Initialization

    /// Initialize a `SendItemAccessCountStepper`.
    ///
    /// - Parameters:
    ///   - currentAccessCount: The number of times the send has been accessed.
    ///   - displayInfoText: Whether the maximum access count info text should be displayed in the footer.
    ///   - maximumAccessCount: A binding for changing the maximum access account for the send in the stepper.
    ///
    init(currentAccessCount: Int?, displayInfoText: Bool = true, maximumAccessCount: Binding<Int>) {
        self.currentAccessCount = currentAccessCount
        self.displayInfoText = displayInfoText
        _maximumAccessCount = maximumAccessCount
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17, *)
#Preview {
    @Previewable @SwiftUI.State var maximumAccessCount = 5

    SendItemAccessCountStepper(currentAccessCount: 0, maximumAccessCount: $maximumAccessCount)
        .padding()
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
