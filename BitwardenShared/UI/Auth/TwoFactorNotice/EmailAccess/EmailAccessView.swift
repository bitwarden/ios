import SwiftUI
import SwiftUIIntrospect

// MARK: - EmailAccessView

/// A view that alerts the user to the new policy of sending emails to confirm new devices.
///
struct EmailAccessView: View {
    // MARK: Properties

    /// An environment variable for getting the vertical size class of the view.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    /// The `Store` for this view.
    @ObservedObject public var store: Store<EmailAccessState, EmailAccessAction, EmailAccessEffect>

    var body: some View {
        VStack(spacing: 12) {
            DynamicImageTextStackView(minHeight: 0) {
                Asset.Images.Illustrations.businessWarning.swiftUIImage
                    .resizable()
                    .frame(
                        width: verticalSizeClass == .regular ? 152 : 124,
                        height: verticalSizeClass == .regular ? 152 : 124
                    )
                    .accessibilityHidden(true)
            } textContent: {
                VStack(spacing: 16) {
                    Text(Localizations.importantNotice)
                        .styleGuide(.title, weight: .bold)

                    Text(Localizations.bitwardenWillSendACodeToYourAccountEmail)
                        .styleGuide(.title3)
                }
                .padding(.horizontal, 12)
            }

            toggleCard
                .padding(.horizontal, 12)

            VStack(spacing: 12) {
                AsyncButton(Localizations.continue) {
                    await store.perform(.continueTapped)
                }
                .buttonStyle(.primary())
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Asset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea())
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        .multilineTextAlignment(.center)
        .scrollView()
    }

    private var toggleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(Localizations.doYouHaveReliableAccessToYourEmail("person\u{2060}@example.com")))
                .styleGuide(.body)
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                .accessibilityHidden(true)

            Divider()

            Toggle(Localizations.yesICanReliablyAccessMyEmail, isOn: store.binding(
                get: \.canAccessEmail,
                send: EmailAccessAction.canAccessEmailChanged
            ))
            .toggleStyle(.bitwarden)
            .accessibilityIdentifier("ItemFavoriteToggle")
        }
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
        .cornerRadius(10)
    }
}

// MARK: - EmailAccessView Previews

#if DEBUG
#Preview("Email Access") {
    NavigationView {
        EmailAccessView(
            store: Store(
                processor: StateProcessor(
                    state: EmailAccessState(
                        allowDelay: true
                    )
                )
            )
        )
    }
}
#endif
