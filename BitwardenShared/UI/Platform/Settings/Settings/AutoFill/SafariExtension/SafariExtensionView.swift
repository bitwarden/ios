import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - SafariExtensionView

/// A setup view for the Safari extension flow.
struct SafariExtensionView: View {
    @ObservedObject var store: Store<SafariExtensionState, SafariExtensionAction, Void>

    private var statusMessage: String {
        if store.state.extensionEnabled {
            return "Safari extension is enabled on this device."
        }

        if store.state.extensionActivated {
            return "Bitwarden opened the Safari setup flow. Finish turning on the extension in Safari."
        }

        return "Set up the Safari extension to fill, save, update, and generate credentials with Bitwarden."
    }

    private var progressLabel: String {
        store.state.extensionEnabled ? "Step 2 of 2" : (store.state.extensionActivated ? "Step 2 of 2" : "Step 1 of 2")
    }

    private var statusLabel: String {
        if store.state.extensionEnabled {
            return "Enabled"
        }

        if store.state.extensionActivated {
            return "Almost done"
        }

        return "Not enabled"
    }

    private var heroTitle: String {
        if store.state.extensionEnabled {
            return "Bitwarden is ready in Safari"
        }

        if store.state.extensionActivated {
            return "Finish setup in Safari"
        }

        return "Set up Bitwarden for Safari"
    }

    private var heroBadgeText: String {
        if store.state.extensionEnabled {
            return "Ready"
        }

        if store.state.extensionActivated {
            return "Continue setup"
        }

        return "Set up now"
    }

    private var heroBadgeStyle: PillBadgeStyle {
        if store.state.extensionEnabled {
            return .success
        }

        return store.state.extensionActivated ? .warning : .warning
    }

    private var nextStepBadgeText: String {
        if store.state.extensionEnabled {
            return "Complete"
        }

        if store.state.extensionActivated {
            return "Needs action"
        }

        return "Start here"
    }

    private var nextStepBadgeStyle: PillBadgeStyle {
        store.state.extensionEnabled ? .success : .warning
    }

    private var nextStepIconSystemName: String {
        if store.state.extensionEnabled {
            return "checkmark.circle.fill"
        }

        if store.state.extensionActivated {
            return "safari.fill"
        }

        return "sparkles"
    }

    private var nextStepIconAccessibilityIdentifier: String {
        if store.state.extensionEnabled {
            return "SafariExtensionNextStepIconReady"
        }

        if store.state.extensionActivated {
            return "SafariExtensionNextStepIconContinue"
        }

        return "SafariExtensionNextStepIconStart"
    }

    private var nextStepTitle: String {
        if store.state.extensionEnabled {
            return "You’re ready"
        }

        if store.state.extensionActivated {
            return "Turn on in Safari"
        }

        return "Activate in Bitwarden"
    }

    private var nextStepMessage: String {
        if store.state.extensionEnabled {
            return "Ready to fill, save, update, and generate credentials in Safari."
        }

        if store.state.extensionActivated {
            return "Safari setup was already opened from Bitwarden. Reopen it if needed, then turn on Bitwarden for Safari."
        }

        return "Start the Safari setup flow in Bitwarden, then turn on the extension in Safari."
    }

    private var nextStepDetails: [(title: String, value: String)] {
        if store.state.extensionEnabled {
            return [
                (title: "Available now", value: "Fill and save from Safari pages"),
                (title: "Also included", value: "Generate passwords without leaving Safari"),
            ]
        }

        if store.state.extensionActivated {
            return [
                (title: "Now", value: "Open the setup sheet again"),
                (title: "Then", value: "Turn on Bitwarden for Safari"),
            ]
        }

        return [
            (title: "Now", value: "Start setup from Bitwarden"),
            (title: "Then", value: "Allow Bitwarden in Safari"),
        ]
    }

    private var activateButtonMessage: String {
        if store.state.extensionActivated {
            return "Bitwarden already opened the Safari setup flow. Reopen it if you still need to finish turning on the extension in Safari."
        }

        return "Starts the Safari setup flow from Bitwarden."
    }

    private var activateButtonTitle: String {
        store.state.extensionActivated ? "Continue Safari Setup" : "Activate Safari Extension"
    }

    private var stepOneStatus: String {
        if store.state.extensionEnabled || store.state.extensionActivated {
            return "Done"
        }

        return "Current step"
    }

    private var stepOneSubtitle: String {
        if store.state.extensionEnabled {
            return "Safari setup completed from Bitwarden."
        }

        if store.state.extensionActivated {
            return "Safari setup was opened from Bitwarden."
        }

        return "Start the Safari setup flow from Bitwarden."
    }

    private var stepTwoStatus: String {
        if store.state.extensionEnabled {
            return "Done"
        }

        return store.state.extensionActivated ? "Current step" : "Up next"
    }

    private var stepTwoSubtitle: String {
        if store.state.extensionEnabled {
            return "Bitwarden is on and ready in Safari."
        }

        if store.state.extensionActivated {
            return "Turn on Bitwarden in Safari to finish setup."
        }

        return "Allow Bitwarden in Safari, then return here."
    }

    private func stepBadgeStyle(for status: String) -> PillBadgeStyle {
        status == "Done" ? .success : .warning
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(spacing: 12) {
                        PillBadgeView(text: heroBadgeText, style: heroBadgeStyle)
                            .frame(maxWidth: .infinity)

                        Text(heroTitle)
                            .styleGuide(.title)
                            .multilineTextAlignment(.center)

                        Text(statusMessage)
                            .styleGuide(.body)
                            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 12) {
                        summaryRow(title: "Status", value: statusLabel)
                        summaryRow(title: "Progress", value: progressLabel)
                    }
                }
                .padding(24)
                .contentBlock()

                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("What you can do")
                    featureRow(title: "Fill", subtitle: "Use page-aware fill suggestions for websites in Safari.")
                    featureRow(title: "Save & Update", subtitle: "Capture new logins and password changes from the current page.")
                    featureRow(title: "Generate", subtitle: "Create strong passwords while staying in the browser flow.")
                }
                .padding(24)
                .contentBlock()

                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Setup checklist")
                    setupStepRow(
                        title: "Activate in Bitwarden",
                        subtitle: stepOneSubtitle,
                        status: stepOneStatus,
                        badgeAccessibilityIdentifier: "SafariExtensionStepOneBadge",
                    )
                    setupStepRow(
                        title: "Turn on in Safari",
                        subtitle: stepTwoSubtitle,
                        status: stepTwoStatus,
                        badgeAccessibilityIdentifier: "SafariExtensionStepTwoBadge",
                    )
                }
                .padding(24)
                .contentBlock()

                VStack(alignment: .leading, spacing: 8) {
                    sectionTitle("Next step")
                    HStack(alignment: .center, spacing: 12) {
                        nextStepIconView()
                        VStack(alignment: .leading, spacing: 8) {
                            PillBadgeView(text: nextStepBadgeText, style: nextStepBadgeStyle)
                                .accessibilityIdentifier("SafariExtensionNextStepBadge")
                            Text(nextStepTitle)
                                .styleGuide(.headline)
                        }
                        Spacer(minLength: 0)
                    }
                    Text(nextStepMessage)
                        .styleGuide(.body)
                        .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(nextStepDetails.enumerated()), id: \.offset) { _, detail in
                            nextStepDetailRow(title: detail.title, value: detail.value)
                        }
                    }
                }
                .padding(24)
                .contentBlock()

                if !store.state.extensionEnabled {
                    VStack(spacing: 8) {
                        Button(activateButtonTitle) {
                            store.send(.activateButtonTapped)
                        }
                        .buttonStyle(.secondary())

                        Text(activateButtonMessage)
                            .styleGuide(.caption1)
                            .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)
            .frame(minHeight: geometry.size.height)
            .scrollView(addVerticalPadding: false)
        }
        .navigationBar(title: "Safari Extension", titleDisplayMode: .inline)
    }

    @ViewBuilder
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .styleGuide(.caption1)
            .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func summaryRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .styleGuide(.caption1)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
            Spacer()
            Text(value)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func nextStepIconView() -> some View {
        Image(systemName: nextStepIconSystemName)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(nextStepBadgeStyle.textColor)
            .frame(width: 36, height: 36)
            .background(nextStepBadgeStyle.backgroundColor)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(nextStepBadgeStyle.borderColor, lineWidth: 1),
            )
            .accessibilityIdentifier(nextStepIconAccessibilityIdentifier)
    }

    @ViewBuilder
    private func nextStepDetailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .styleGuide(.caption1)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
            Text(value)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func featureRow(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .styleGuide(.headline)
            Text(subtitle)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func setupStepRow(
        title: String,
        subtitle: String,
        status: String,
        badgeAccessibilityIdentifier: String,
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Text(title)
                    .styleGuide(.headline)
                Spacer()
                PillBadgeView(text: status, style: stepBadgeStyle(for: status))
                    .accessibilityIdentifier(badgeAccessibilityIdentifier)
            }

            Text(subtitle)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SafariExtensionView(
        store: Store(
            processor: StateProcessor(state: SafariExtensionState()),
        ),
    )
}
