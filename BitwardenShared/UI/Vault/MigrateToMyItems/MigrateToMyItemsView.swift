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
            case .extensionPrompt:
                extensionPromptPage
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
                } else if store.state.isExtension {
                    closeToolbarButton {
                        store.send(.closeTapped)
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
            ) {
                Text(LocalizedStringKey(
                    Localizations.learnMoreLink(
                        ExternalLinksConstants.transferOwnership,
                    ),
                ))
                .styleGuide(.body, weight: .semibold)
                .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                .tint(SharedAsset.Colors.buttonOutlinedForeground.swiftUIColor)
                // we need this moved up a bit to look like it's continuing
                // from the previous "message" paragraph without much space between them.
                .padding(.top, -8)
            }

            VStack(spacing: 12) {
                AsyncButton(Localizations.acceptTransfer) {
                    await store.perform(.acceptTransferTapped)
                }
                .buttonStyle(.primary())

                Button(Localizations.declineAndLeave) {
                    store.send(.declineAndLeaveTapped)
                }
                .buttonStyle(.bitwardenBorderless(size: .medium))
            }
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
                VStack(spacing: 8) {
                    Text(LocalizedStringKey(
                        Localizations.learnMoreLink(
                            ExternalLinksConstants.transferOwnership,
                        ),
                    ))
                    .styleGuide(.body, weight: .semibold)
                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                    .tint(SharedAsset.Colors.buttonOutlinedForeground.swiftUIColor)

                    Text(Localizations.contactYourAdminToRegainAccess)
                        .styleGuide(.body)
                        .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                }
                // we need this moved up a bit to look like it's continuing
                // from the previous "message" paragraph without much space between them.
                .padding(.top, -8)
            }

            VStack(spacing: 12) {
                AsyncButton(Localizations.leaveX(store.state.organizationName)) {
                    await store.perform(.leaveOrganizationTapped)
                }
                .buttonStyle(.primary(isDestructive: true))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
        .scrollView()
    }

    /// The page shown in app extensions prompting the user to complete migration in the main app.
    private var extensionPromptPage: some View {
        VStack(spacing: 24) {
            IllustratedMessageView(
                image: Asset.Images.Illustrations.itemTransfer,
                style: .mediumImage,
                title: Localizations.itemTransfer,
                message: Localizations.itemTransferRequiresMainAppDescriptionLong,
            )

            Button(Localizations.continueToBitwarden) {
                openURL(ExternalLinksConstants.appDeepLink)
                store.send(.continueToBitwardenTapped)
            }
            .buttonStyle(.primary())
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
