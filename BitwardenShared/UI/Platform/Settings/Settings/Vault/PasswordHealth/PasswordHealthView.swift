import BitwardenKit
import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - PasswordHealthView

/// A view that shows password health information for the user's vault, starting with reused passwords.
///
struct PasswordHealthView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<PasswordHealthState, PasswordHealthAction, PasswordHealthEffect>

    // MARK: View

    var body: some View {
        LoadingView(state: store.state.loadingState) { groups in
            if groups.isEmpty {
                emptyReusedPasswords
                    .scrollView(centerContentVertically: true)
            } else {
                reusedPasswordsList(groups)
                    .scrollView()
            }
        }
        .navigationBar(title: Localizations.passwordHealth, titleDisplayMode: .inline)
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea())
        .task {
            await store.perform(.loadData)
        }
    }

    // MARK: Private Views

    /// The empty state shown when no reused passwords are detected.
    private var emptyReusedPasswords: some View {
        VStack(spacing: 12) {
            Image(asset: SharedAsset.Icons.check24)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundStyle(SharedAsset.Colors.iconSecondary.swiftUIColor)

            Text(Localizations.reusedPasswords)
                .styleGuide(.title2, weight: .semibold)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

            Text(Localizations.noReusedPasswords)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .accessibilityIdentifier("NoReusedPasswordsView")
    }

    /// The list of reused password groups.
    ///
    /// - Parameter groups: The reused password groups to display.
    ///
    private func reusedPasswordsList(_ groups: [ReusedPasswordGroup]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(Localizations.reusedPasswords)
                .styleGuide(.title3, weight: .semibold)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            ForEach(groups) { group in
                reusedPasswordGroup(group)
            }
        }
        .padding(.bottom, 16)
    }

    /// A section for a single group of ciphers that share the same password.
    ///
    /// - Parameter group: The reused password group to display.
    ///
    private func reusedPasswordGroup(_ group: ReusedPasswordGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localizations.xAccountsUseThisPassword(group.ciphers.count))
                .styleGuide(.footnote, weight: .semibold)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

            ContentBlock(dividerLeadingPadding: 16) {
                ForEach(group.ciphers, id: \.id) { cipher in
                    Button {
                        store.send(.itemPressed(cipher))
                    } label: {
                        cipherRow(for: cipher)
                    }
                    .accessibilityIdentifier("ReusedPasswordCipherItem")
                }
            }
        }
    }

    /// A row displaying a single cipher's name and username.
    ///
    /// - Parameter cipher: The `CipherListView` to display.
    ///
    private func cipherRow(for cipher: CipherListView) -> some View {
        HStack {
            Image(asset: SharedAsset.Icons.globe24)
                .imageStyle(.rowIcon)

            VStack(alignment: .leading, spacing: 2) {
                Text(cipher.name)
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .lineLimit(1)

                if let username = cipher.type.loginListView?.username, !username.isEmpty {
                    Text(username)
                        .styleGuide(.subheadline)
                        .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("No Reused Passwords") {
    NavigationView {
        PasswordHealthView(
            store: Store(
                processor: StateProcessor(
                    state: PasswordHealthState(loadingState: .data([])),
                ),
            ),
        )
    }
}

#Preview("Reused Passwords") {
    NavigationView {
        PasswordHealthView(
            store: Store(
                processor: StateProcessor(
                    state: PasswordHealthState(
                        loadingState: .data([
                            ReusedPasswordGroup(
                                id: "abc123",
                                ciphers: [
                                    .fixture(
                                        id: "1",
                                        login: .fixture(username: "user@example.com"),
                                        name: "Example Site",
                                    ),
                                    .fixture(
                                        id: "2",
                                        login: .fixture(username: "user@example.com"),
                                        name: "Another Site",
                                    ),
                                ],
                            ),
                        ]),
                    ),
                ),
            ),
        )
    }
}
#endif
