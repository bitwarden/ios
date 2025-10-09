import BitwardenKit
import BitwardenResources
import SwiftUI

public struct ProfileSwitcherSheet: View {
    /// The `Store` for this view.
    @ObservedObject var store: Store<ProfileSwitcherState, ProfileSwitcherAction, ProfileSwitcherEffect>

    public var body: some View {
        ZStack {
            SharedAsset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea()

            SectionView(Localizations.selectAccount) {
                ProfileSwitcherAccountsView(store: store)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                if store.state.showsAddAccount {
                    addAccountRow
                }
            }
            .padding(.horizontal, 12)
        }
        .navigationBar(title: Localizations.accounts, titleDisplayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                closeToolbarButton {
                    store.send(.dismissTapped)
                }
            }
        }
        .task {
            await store.perform(.refreshAccountProfiles)
        }
        .scrollView()
    }

    // MARK: Private Properties

    /// A row to add an account
    @ViewBuilder private var addAccountRow: some View {
        AsyncButton {
            await store.perform(.addAccountPressed)
        } label: {
            Label(Localizations.addAccount, image: SharedAsset.Icons.plus16.swiftUIImage)
        }
        .buttonStyle(.bitwardenBorderless)
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityIdentifier("AddAccountButton")
    }
}

// MARK: Previews

#if DEBUG
@available(iOS 16.0, *)
#Preview("Single Account") {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            NavigationView {
                ProfileSwitcherSheet(
                    store: Store(
                        processor: StateProcessor(
                            state: .singleAccount,
                        ),
                    ),
                )
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
}

@available(iOS 16.0, *)
#Preview("Dual Account") {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            NavigationView {
                ProfileSwitcherSheet(
                    store: Store(
                        processor: StateProcessor(
                            state: .dualAccounts,
                        ),
                    ),
                )
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
}

@available(iOS 16.0, *)
#Preview("Many Accounts") {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            NavigationView {
                ProfileSwitcherSheet(
                    store: Store(
                        processor: StateProcessor(
                            state: .subMaximumAccounts,
                        ),
                    ),
                )
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
}

@available(iOS 16.0, *)
#Preview("Max Accounts") {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            NavigationView {
                ProfileSwitcherSheet(
                    store: Store(
                        processor: StateProcessor(
                            state: .maximumAccounts,
                        ),
                    ),
                )
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
}
#endif
