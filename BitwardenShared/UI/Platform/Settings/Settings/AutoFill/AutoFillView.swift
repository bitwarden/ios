import BitwardenResources
import SwiftUI

// MARK: - AutoFillView

/// A view for configuring auto-fill settings.
///
struct AutoFillView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<AutoFillState, AutoFillAction, AutoFillEffect>

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            autofillActionCard

            autoFillSection

            additionalOptionsSection
        }
        .animation(.easeInOut, value: store.state.badgeState?.autofillSetupProgress == .complete)
        .scrollView()
        .navigationBar(title: Localizations.autofill, titleDisplayMode: .inline)
        .task {
            await store.perform(.fetchSettingValues)
        }
        .task {
            await store.perform(.streamSettingsBadge)
        }
    }

    // MARK: Private views

    /// The action card for setting up autofill.
    @ViewBuilder private var autofillActionCard: some View {
        if store.state.shouldShowAutofillActionCard {
            ActionCard(
                title: Localizations.setUpAutofill,
                actionButtonState: ActionCard.ButtonState(title: Localizations.getStarted) {
                    store.send(.showSetUpAutofill)
                },
                dismissButtonState: ActionCard.ButtonState(title: Localizations.dismiss) {
                    await store.perform(.dismissSetUpAutofillActionCard)
                }
            ) {
                BitwardenBadge(badgeValue: "1")
            }
        }
    }

    /// The additional options section.
    private var additionalOptionsSection: some View {
        SectionView(Localizations.additionalOptions, contentSpacing: 8) {
            BitwardenToggle(
                Localizations.copyTotpAutomatically,
                footer: Localizations.copyTotpAutomaticallyDescription,
                isOn: store.binding(
                    get: \.isCopyTOTPToggleOn,
                    send: AutoFillAction.toggleCopyTOTPToggle
                ),
                accessibilityIdentifier: "CopyTotpAutomaticallySwitch"
            )
            .contentBlock()

            BitwardenMenuField(
                title: Localizations.defaultUriMatchDetection,
                footer: Localizations.defaultUriMatchDetectionDescription,
                accessibilityIdentifier: "DefaultUriMatchDetectionChooser",
                options: UriMatchType.allCases,
                selection: store.binding(
                    get: \.defaultUriMatchType,
                    send: AutoFillAction.defaultUriMatchTypeChanged
                )
            )
        }
    }

    /// The auto-fill section.
    private var autoFillSection: some View {
        SectionView(Localizations.autofill, contentSpacing: 8) {
            ContentBlock(dividerLeadingPadding: 16) {
                SettingsListItem(Localizations.passwordAutofill) {
                    store.send(.passwordAutoFillTapped)
                }

                SettingsListItem(Localizations.appExtension) {
                    store.send(.appExtensionTapped)
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationView {
        AutoFillView(store: Store(processor: StateProcessor(state: AutoFillState())))
    }
}

#Preview("Autofill Action Card") {
    NavigationView {
        AutoFillView(store: Store(processor: StateProcessor(state: AutoFillState(
            badgeState: .fixture(autofillSetupProgress: .setUpLater)
        ))))
    }
}
#endif
