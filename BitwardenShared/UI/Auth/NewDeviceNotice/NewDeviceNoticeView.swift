import SwiftUI

// MARK: - NewDeviceNoticeView

/// A view that alerts the user to the new policy of sending emails to confirm new devices.
///
struct NewDeviceNoticeView: View {
    // MARK: Properties

    /// An environment variable for getting the vertical size class of the view.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    /// The `Store` for this view.
    @ObservedObject public var store: Store<NewDeviceNoticeState, NewDeviceNoticeAction, NewDeviceNoticeEffect>

    var body: some View {
        VStack(spacing: 12) {
            dynamicStackView(minHeight: 0) {
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

            Spacer()
        }
        .task {
            await store.perform(.appeared)
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
                send: NewDeviceNoticeAction.canAccessEmailChanged
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

    /// A dynamic stack view that lays out content vertically when in a regular vertical size class
    /// and horizontally for the compact vertical size class.
    @ViewBuilder
    private func dynamicStackView(
        minHeight: CGFloat,
        @ViewBuilder imageContent: () -> some View,
        @ViewBuilder textContent: () -> some View
    ) -> some View {
        Group {
            if verticalSizeClass == .regular {
                VStack(spacing: 24) {
                    imageContent()
                    textContent()
                }
                .padding(.top, 32)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, minHeight: minHeight)
            } else {
                HStack(alignment: .top, spacing: 40) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        imageContent()
                            .padding(.leading, 36)
                            .padding(.vertical, 16)
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: minHeight)

                    textContent()
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, minHeight: minHeight)
                }
            }
        }
    }
}

// MARK: - NewDeviceNoticeView Previews

#if DEBUG
#Preview("New Device Notice") {
    NavigationView {
        NewDeviceNoticeView(
            store: Store(
                processor: StateProcessor(
                    state: NewDeviceNoticeState(
                        canAccessEmail: false
                    )
                )
            )
        )
    }
}
#endif
