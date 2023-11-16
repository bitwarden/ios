import SwiftUI

// MARK: - AutoFillView

/// A view for configuring auto-fill settings.
///
struct AutoFillView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<AutoFillState, AutoFillAction, Void>

    // MARK: View

    var body: some View {
        VStack(spacing: 20) {
            autoFillSection

            additionalOptionsSection
        }
        .scrollView()
        .navigationBar(title: Localizations.autofill, titleDisplayMode: .inline)
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
    }

    // MARK: Private views

    /// The additional options section.
    private var additionalOptionsSection: some View {
        VStack(alignment: .leading) {
            sectionHeader(Localizations.additionalOptions)

            VStack(alignment: .leading, spacing: 6) {
                ToggleView(
                    isOn: store.binding(
                        get: \.isCopyTOTPToggleOn,
                        send: AutoFillAction.toggleCopyTOTPToggle
                    ),
                    description: Localizations.copyTotpAutomatically
                )

                Text(Localizations.copyTotpAutomaticallyDescription)
                    .font(.styleGuide(.subheadline))
                    .foregroundColor(Color(asset: Asset.Colors.textSecondary))
            }
            .padding(.bottom, 12)

            VStack(spacing: 2) {
                SettingsListItem(
                    Localizations.defaultUriMatchDetection,
                    hasDivider: false
                ) {} trailingContent: {
                    Text(Localizations.baseDomain) // TODO: BIT-1185 Dynamic value
                }
                .cornerRadius(10)
                .padding(.bottom, 8)

                Text(Localizations.defaultUriMatchDetectionDescription)
                    .font(.styleGuide(.subheadline))
                    .foregroundColor(Color(asset: Asset.Colors.textSecondary))
            }
        }
    }

    /// The auto-fill section.
    private var autoFillSection: some View {
        VStack(alignment: .leading) {
            sectionHeader(Localizations.autofill)

            VStack(spacing: 0) {
                SettingsListItem(Localizations.passwordAutofill) {}

                SettingsListItem(
                    Localizations.appExtension,
                    hasDivider: false
                ) {}
            }
            .cornerRadius(10)
        }
    }

    /// A section header.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .accessibilityAddTraits(.isHeader)
            .font(.styleGuide(.footnote))
            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
            .textCase(.uppercase)
    }
}

// MARK: Previews

struct AutoFillView_Previews: PreviewProvider {
    static var previews: some View {
        AutoFillView(store: Store(processor: StateProcessor(state: AutoFillState())))
    }
}
