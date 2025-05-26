import SwiftUI

// MARK: - SendItemAccessCountStepper

/// A view containing the stepper component for a send's maximum access count.
///
struct SendItemAccessCountStepper: View {
    // MARK: Properties

    /// The number of times the send has been accessed.
    let currentAccessCount: Int?

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
                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            } footer: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Localizations.maximumAccessCountInfo)
                        .styleGuide(.footnote)
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

                    if let currentAccessCount {
                        // Wrap these texts in a group so that the style guide can be set on
                        // both of them at once.
                        Group {
                            Text("\(Localizations.currentAccessCount): ")
                                + Text("\(currentAccessCount)")
                                .fontWeight(.bold)
                        }
                        .styleGuide(.footnote)
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    }
                }
            }
            .accessibilityIdentifier("SendMaxAccessCountEntry")
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17, *)
#Preview {
    @Previewable @SwiftUI.State var maximumAccessCount = 5

    SendItemAccessCountStepper(currentAccessCount: 0, maximumAccessCount: $maximumAccessCount)
        .padding()
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
}
#endif
