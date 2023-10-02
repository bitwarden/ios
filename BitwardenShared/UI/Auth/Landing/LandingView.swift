import SwiftUI

// MARK: - LandingView

/// A view that allows the user to input their email address to begin the login flow,
/// or allows the user to navigate to the account creation flow.
///
struct LandingView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject public var store: Store<LandingState, LandingAction, Void>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(decorative: Asset.Images.logo)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 45)

                Text(Localizations.loginOrCreateNewAccount)
                    .font(.system(.title2))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .frame(maxWidth: .infinity)

                BitwardenTextField(
                    title: Localizations.emailAddress,
                    contentType: .emailAddress,
                    text: store.binding(
                        get: \.email,
                        send: LandingAction.emailChanged
                    )
                )
                .textInputAutocapitalization(.never)

                Button {
                    store.send(.regionPressed)
                } label: {
                    Group {
                        Text("\(Localizations.region): ")
                            .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                            + Text(Localizations.us)
                            .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                    }
                    .font(.system(.subheadline))
                }

                Toggle(Localizations.rememberMe, isOn: store.binding(
                    get: { $0.isRememberMeOn },
                    send: { .rememberMeChanged($0) }
                ))
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                .tint(Asset.Colors.primaryBitwarden.swiftUIColor)

                Button(Localizations.continue) {
                    store.send(.continuePressed)
                }
                .buttonStyle(.primary())

                HStack(spacing: 4) {
                    Text(Localizations.newAroundHere)
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    Button(Localizations.createAccount) {
                        store.send(.createAccountPressed)
                    }
                    .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                }
                .font(.system(.footnote))
            }
            .padding([.horizontal, .bottom], 16)
        }
        .background(Asset.Colors.backgroundGroupedPrimary.swiftUIColor.ignoresSafeArea())
        .navigationBarTitle(Localizations.bitwarden, displayMode: .inline)
    }
}

// MARK: - Previews

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LandingView(
                store: Store(
                    processor: StateProcessor(
                        state: LandingState(
                            email: "",
                            isRememberMeOn: false
                        )
                    )
                )
            )
        }
        .previewDisplayName("Empty Email")

        NavigationView {
            LandingView(
                store: Store(
                    processor: StateProcessor(
                        state: LandingState(
                            email: "email@example.com",
                            isRememberMeOn: true
                        )
                    )
                )
            )
        }
        .previewDisplayName("Example Email")
    }
}
