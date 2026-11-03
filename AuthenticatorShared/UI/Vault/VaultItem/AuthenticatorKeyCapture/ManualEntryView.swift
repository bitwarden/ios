import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - ManualEntryView

/// A view for the user to manually enter an authenticator key.
///
struct ManualEntryView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ManualEntryState, ManualEntryAction, ManualEntryEffect>

    var body: some View {
        content
            .navigationBar(
                title: Localizations.createVerificationCode,
                titleDisplayMode: .inline,
            )
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismissPressed)
                }
            }
            .task {
                await store.perform(.appeared)
            }
    }

    /// A button to trigger an `.addPressed(:)` action.
    ///
    private var addButton: some View {
        Button(Localizations.addCode) {
            store.send(
                ManualEntryAction.addPressed(
                    code: store.state.authenticatorKey,
                    name: store.state.name,
                    sendToBitwarden: false,
                ),
            )
        }
        .buttonStyle(.primary())
        .accessibilityIdentifier("ManualEntryAddCodeButton")
    }

    /// The main content of the view.
    ///
    private var content: some View {
        VStack(alignment: .center, spacing: 16.0) {
            Text(Localizations.enterKeyManually)
                .styleGuide(.title2, weight: .bold)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
            BitwardenTextField(
                title: Localizations.name,
                text: store.binding(
                    get: \.name,
                    send: ManualEntryAction.nameChanged,
                ),
                accessibilityIdentifier: "ManualEntryNameField",
            )

            BitwardenTextField(
                title: Localizations.key,
                text: store.binding(
                    get: \.authenticatorKey,
                    send: ManualEntryAction.authenticatorKeyChanged,
                ),
                accessibilityIdentifier: "ManualEntryKeyField",
            )

            if store.state.isPasswordManagerSyncActive {
                if store.state.defaultSaveOption == .saveHere {
                    addPrimaryButton(sendToBitwarden: false)
                    addSecondaryButton(sendToBitwarden: true)
                } else {
                    addPrimaryButton(sendToBitwarden: true)
                    addSecondaryButton(sendToBitwarden: false)
                }
            } else {
                addButton
            }
            footerButtonContainer
        }
        .background(
            SharedAsset.Colors.backgroundPrimary.swiftUIColor
                .ignoresSafeArea(),
        )
        .scrollView()
    }

    /// A view to wrap the button for triggering `.scanCodePressed`.
    ///
    @ViewBuilder private var footerButtonContainer: some View {
        if store.state.deviceSupportsCamera {
            AsyncButton {
                await store.perform(.scanCodePressed)
            } label: {
                Text(styledFooterText())
                    .styleGuide(.subheadline)
            }
            .buttonStyle(InlineButtonStyle())
        }
    }

    /// Create a button to trigger an `.addPressed(:)` action.
    ///
    /// - Parameter sendToBitwarden: whether this button sends the code to Bitwarden (`true`) or stores
    ///     it locally (`false`). This is also used to determine the title and accessibility identifier.
    /// - Returns: the configured `Button`.
    ///
    private func addButton(sendToBitwarden: Bool) -> some View {
        let accessibilityIdentifier = sendToBitwarden
            ? "ManualEntryAddCodeToBitwardenButton"
            : "ManualEntryAddCodeButton"
        let title = sendToBitwarden
            ? Localizations.saveToBitwarden
            : Localizations.saveHere

        return Button(title) {
            store.send(
                ManualEntryAction.addPressed(
                    code: store.state.authenticatorKey,
                    name: store.state.name,
                    sendToBitwarden: sendToBitwarden,
                ),
            )
        }
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    /// A primary style button to trigger an `.addPressed(:)` action.
    ///
    /// - Parameter sendToBitwarden: whether this button sends the code to Bitwarden (`true`) or stores
    ///     it locally (`false`). This is also used to determine the title and accessibility identifier.
    /// - Returns: the `Button`, styled and configured.
    ///
    private func addPrimaryButton(sendToBitwarden: Bool) -> some View {
        addButton(sendToBitwarden: sendToBitwarden)
            .buttonStyle(.primary())
    }

    /// A secondary style button to trigger an `.addPressed(:)` action.
    ///
    /// - Parameter sendToBitwarden: whether this button sends the code to Bitwarden (`true`) or stores
    ///     it locally (`false`). This is also used to determine the title and accessibility identifier.
    /// - Returns: the `Button`, styled and configured.
    ///
    private func addSecondaryButton(sendToBitwarden: Bool) -> some View {
        addButton(sendToBitwarden: sendToBitwarden)
            .buttonStyle(.secondary())
    }

    /// Creates an attributed string with the footer text, styling the "Scan QR Code" portion with
    /// the correct color.
    ///
    /// - Returns: An `AttributedString` of the footer text, styled to highlight the call to action.
    ///
    private func styledFooterText() -> AttributedString {
        var attributed = AttributedString(
            Localizations.cannotAddAuthenticatorKey + " " + Localizations.scanQRCode,
        )
        attributed.foregroundColor = SharedAsset.Colors.textSecondary.swiftUIColor
        if let range = attributed.range(of: Localizations.scanQRCode) {
            attributed[range].foregroundColor = SharedAsset.Colors.textInteraction.swiftUIColor
        }
        return attributed
    }
}

#if DEBUG
private struct ManualEntryPreviewState: ManualEntryState {
    var authenticatorKey: String = ""

    var defaultSaveOption: DefaultSaveOption = .none

    var deviceSupportsCamera: Bool = true

    var isPasswordManagerSyncActive: Bool = false

    var manualEntryState: ManualEntryState {
        self
    }

    var name: String = ""
}

#Preview("Empty") {
    NavigationView {
        ManualEntryView(
            store: Store(
                processor: StateProcessor(
                    state: ManualEntryPreviewState().manualEntryState,
                ),
            ),
        )
    }
}

#Preview("Text Added") {
    NavigationView {
        ManualEntryView(
            store: Store(
                processor: StateProcessor(
                    state: ManualEntryPreviewState(
                        authenticatorKey: "manualEntry",
                        name: "Manual Name",
                    ).manualEntryState,
                ),
            ),
        )
    }
}

#Preview("Sync Active - No default") {
    NavigationView {
        ManualEntryView(
            store: Store(
                processor: StateProcessor(
                    state: ManualEntryPreviewState(
                        defaultSaveOption: .none,
                        isPasswordManagerSyncActive: true,
                    ).manualEntryState,
                ),
            ),
        )
    }
}

#Preview("Sync Active - Bitwarden default") {
    NavigationView {
        ManualEntryView(
            store: Store(
                processor: StateProcessor(
                    state: ManualEntryPreviewState(
                        defaultSaveOption: .saveToBitwarden,
                        isPasswordManagerSyncActive: true,
                    ).manualEntryState,
                ),
            ),
        )
    }
}

#Preview("Sync Active - Local default") {
    NavigationView {
        ManualEntryView(
            store: Store(
                processor: StateProcessor(
                    state: ManualEntryPreviewState(
                        defaultSaveOption: .saveHere,
                        isPasswordManagerSyncActive: true,
                    ).manualEntryState,
                ),
            ),
        )
    }
}
#endif
