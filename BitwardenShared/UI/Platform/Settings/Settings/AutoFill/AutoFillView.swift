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
        VStack(spacing: 20) {
            autoFillSection

            additionalOptionsSection
        }
        .scrollView()
        .navigationBar(title: Localizations.autofill, titleDisplayMode: .inline)
        .task {
            await store.perform(.fetchSettingValues)
        }
    }

    // MARK: Private views

    /// The additional options section.
    private var additionalOptionsSection: some View {
        VStack(alignment: .leading) {
            SectionHeaderView(Localizations.additionalOptions)

            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: store.binding(
                    get: \.isCopyTOTPToggleOn,
                    send: AutoFillAction.toggleCopyTOTPToggle
                )) {
                    Text(Localizations.copyTotpAutomatically)
                }
                .toggleStyle(.bitwarden)
                .styleGuide(.body)
                .accessibilityIdentifier("CopyTotpAutomaticallySwitch")

                Text(Localizations.copyTotpAutomaticallyDescription)
                    .styleGuide(.subheadline)
                    .foregroundColor(Color(asset: Asset.Colors.textSecondary))
            }
            .padding(.bottom, 12)

            VStack(spacing: 2) {
                SettingsMenuField(
                    title: Localizations.defaultUriMatchDetection,
                    options: UriMatchType.allCases,
                    hasDivider: false,
                    selection: store.binding(
                        get: \.defaultUriMatchType,
                        send: AutoFillAction.defaultUriMatchTypeChanged
                    )
                )
                .cornerRadius(10)
                .padding(.bottom, 8)
                .accessibilityIdentifier("DefaultUriMatchDetectionChooser")

                Text(Localizations.defaultUriMatchDetectionDescription)
                    .styleGuide(.subheadline)
                    .foregroundColor(Color(asset: Asset.Colors.textSecondary))
            }
        }
    }

    /// The auto-fill section.
    private var autoFillSection: some View {
        VStack(alignment: .leading) {
            SectionHeaderView(Localizations.autofill)

            VStack(spacing: 0) {
                SettingsListItem(Localizations.passwordAutofill) {
                    store.send(.passwordAutoFillTapped)
                }

                SettingsListItem(
                    Localizations.appExtension,
                    hasDivider: false
                ) {
                    store.send(.appExtensionTapped)
                }
            }
            .cornerRadius(10)
        }
    }
}

// MARK: - Previews

#Preview {
    AutoFillView(store: Store(processor: StateProcessor(state: AutoFillState())))
}
