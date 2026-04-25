import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - SafariExtensionView

/// A temporary setup view for the Safari extension flow.
struct SafariExtensionView: View {
    @ObservedObject var store: Store<SafariExtensionState, SafariExtensionAction, Void>

    private var statusMessage: String {
        if store.state.extensionEnabled {
            return "Safari extension is enabled on this device."
        }

        if store.state.extensionActivated {
            return "Continue the Safari setup flow to finish enabling the extension."
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

    private var nextStepTitle: String {
        if store.state.extensionEnabled {
            return "You’re ready"
        }

        if store.state.extensionActivated {
            return "Continue in Safari"
        }

        return "Get started"
    }

    private var nextStepMessage: String {
        if store.state.extensionEnabled {
            return "Ready to fill, save, update, and generate credentials in Safari."
        }

        if store.state.extensionActivated {
            return "Open the Safari setup sheet again, then turn on Bitwarden for Safari."
        }

        return "Activate Bitwarden, then allow it in Safari settings."
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

    private var stepTwoStatus: String {
        if store.state.extensionEnabled {
            return "Done"
        }

        return store.state.extensionActivated ? "Current step" : "Up next"
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(progressLabel)
                            .styleGuide(.caption2)
                            .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                        Spacer()
                        Text(statusLabel)
                            .styleGuide(.caption2)
                            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
                            .clipShape(Capsule())
                    }

                    VStack(spacing: 12) {
                        Text("Safari Extension")
                            .styleGuide(.title)
                            .multilineTextAlignment(.center)

                        Text(statusMessage)
                            .styleGuide(.body)
                            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(24)
                .contentBlock()

                VStack(alignment: .leading, spacing: 12) {
                    featureRow(title: "Fill", subtitle: "Use page-aware fill suggestions for websites in Safari.")
                    featureRow(title: "Save & Update", subtitle: "Capture new logins and password changes from the current page.")
                    featureRow(title: "Generate", subtitle: "Create strong passwords while staying in the browser flow.")
                }
                .padding(24)
                .contentBlock()

                VStack(alignment: .leading, spacing: 12) {
                    setupStepRow(
                        title: "Activate in Bitwarden",
                        subtitle: "Start the Safari setup flow from Bitwarden.",
                        status: stepOneStatus,
                    )
                    setupStepRow(
                        title: "Turn on in Safari Settings",
                        subtitle: "Allow Bitwarden in Safari, then return here.",
                        status: stepTwoStatus,
                    )
                }
                .padding(24)
                .contentBlock()

                VStack(alignment: .leading, spacing: 8) {
                    Text(nextStepTitle)
                        .styleGuide(.headline)
                    Text(nextStepMessage)
                        .styleGuide(.body)
                        .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
                .contentBlock()

                if !store.state.extensionEnabled {
                    Button(activateButtonTitle) {
                        store.send(.activateButtonTapped)
                    }
                    .buttonStyle(.secondary())
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
    private func setupStepRow(title: String, subtitle: String, status: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Text(title)
                    .styleGuide(.headline)
                Spacer()
                Text(status)
                    .styleGuide(.caption2)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
                    .clipShape(Capsule())
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
