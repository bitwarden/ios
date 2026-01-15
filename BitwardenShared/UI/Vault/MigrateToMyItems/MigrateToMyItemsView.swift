import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - MigrateToMyItemsView

/// A view that prompts the user to accept or decline an item transfer request from an organization.
///
struct MigrateToMyItemsView: View {
    // MARK: Properties

    /// An object used to open URLs from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<MigrateToMyItemsState, MigrateToMyItemsAction, MigrateToMyItemsEffect>

    // MARK: View

    var body: some View {
        Group {
            switch store.state.page {
            case .transfer:
                transferPage
            case .declineConfirmation:
                declineConfirmationPage
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: store.state.page)
        .navigationBar(title: Localizations.itemTransfer, titleDisplayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if store.state.page == .declineConfirmation {
                    backToolbarButton {
                        store.send(.backTapped)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .task {
            await store.perform(.appeared)
        }
    }

    // MARK: Private Views

    /// The main transfer page prompting the user to accept or decline.
    private var transferPage: some View {
        VStack(spacing: 24) {
            IllustratedMessageView(
                image: Asset.Images.Illustrations.itemTransfer,
                style: .mediumImage,
                title: Localizations.transferItemsToX(store.state.organizationName),
                message: Localizations.xIsRequiringAllItemsToBeOwnedByTheOrganizationDescriptionLong(
                    store.state.organizationName,
                ),
            )

            VStack(spacing: 12) {
                AsyncButton(Localizations.accept) {
                    await store.perform(.acceptTransferTapped)
                }
                .buttonStyle(.primary())

                Button(Localizations.declineAndLeave) {
                    store.send(.declineAndLeaveTapped)
                }
                .buttonStyle(.secondary())
            }

            Button {
                openURL(ExternalLinksConstants.transferOwnership)
            } label: {
                Text(Localizations.whyAmISeeingThis)
            }
            .buttonStyle(.bitwardenBorderless)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
        .scrollView()
    }

    /// The decline confirmation page warning the user about leaving the organization.
    private var declineConfirmationPage: some View {
        VStack(spacing: 24) {
            IllustratedMessageView(
                image: Asset.Images.Illustrations.itemTransferWarning,
                style: .mediumImage,
                title: Localizations.areYouSureYouWantToLeave,
                message: Localizations.byDecliningYourPersonalItemsWillStayInYourAccountDescriptionLong,
            ) {
                Text(Localizations.contactYourAdminToRegainAccess)
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .padding(.top, 8)
            }

            VStack(spacing: 12) {
                AsyncButton(Localizations.leaveX(store.state.organizationName)) {
                    await store.perform(.leaveOrganizationTapped)
                }
                .buttonStyle(.primary(isDestructive: true))
            }

            Button {
                openURL(ExternalLinksConstants.transferOwnership)
            } label: {
                Text(Localizations.howToManageMyVault)
            }
            .buttonStyle(.bitwardenBorderless)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
        .scrollView()
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Transfer") {
    MigrateToMyItemsView(
        store: Store(
            processor: StateProcessor(
                state: MigrateToMyItemsState(
                    organizationId: "org-123",
                    organizationName: "Acme",
                ),
            ),
        ),
    )
    .navStackWrapped
}

#Preview("Decline Confirmation") {
    MigrateToMyItemsView(
        store: Store(
            processor: StateProcessor(
                state: MigrateToMyItemsState(
                    organizationId: "org-123",
                    organizationName: "Acme",
                    page: .declineConfirmation,
                ),
            ),
        ),
    )
    .navStackWrapped
}
#endif
