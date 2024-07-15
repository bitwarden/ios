import BitwardenSdk
import SwiftUI

// MARK: - ViewItemView

/// A view that displays the contents of a vault item.
struct ViewItemView: View {
    // MARK: Private Properties

    /// An environment variable used to open URLs.
    @Environment(\.openURL) private var openURL

    // MARK: Properties

    /// Whether to show the collections option in the toolbar menu.
    var isCollectionsEnabled: Bool {
        guard let cipher = store.state.loadingState.data?.cipher else { return false }
        return cipher.organizationId != nil
    }

    /// Whether to show the move to organization option in the toolbar menu.
    var isMoveToOrganizationEnabled: Bool {
        guard let cipher = store.state.loadingState.data?.cipher else { return false }
        return cipher.organizationId == nil
    }

    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewItemState, ViewItemAction, ViewItemEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    // MARK: View

    var body: some View {
        LoadingView(state: store.state.loadingState) { state in
            if let viewState = state.viewState {
                details(for: viewState)
            }
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toast(store.binding(
            get: \.toast,
            send: ViewItemAction.toastShown
        ))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                VaultItemManagementMenuView(
                    isCloneEnabled: store.state.canClone,
                    isCollectionsEnabled: isCollectionsEnabled,
                    isMoveToOrganizationEnabled: isMoveToOrganizationEnabled,
                    store: store.child(
                        state: { _ in },
                        mapAction: { .morePressed($0) },
                        mapEffect: { _ in .deletePressed }
                    )
                )

                closeToolbarButton {
                    store.send(.dismissPressed)
                }
            }
        }
        .task {
            await store.perform(.appeared)
        }
    }

    /// The title of the view
    private var navigationTitle: String {
        Localizations.viewItem
    }

    // MARK: Private Views

    /// The details of the item. This view wraps all of the different detail views for
    /// the different types of items into one variable, so that the edit button can be
    /// added to all of them at once.
    @ViewBuilder
    private func details(for state: ViewVaultItemState) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ViewItemDetailsView(
                    store: store.child(
                        state: { _ in state },
                        mapAction: { $0 },
                        mapEffect: { $0 }
                    ),
                    timeProvider: timeProvider
                )
            }
            .padding(16)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if state.isSoftDeleted {
                    toolbarButton(Localizations.restore) {
                        await store.perform(.restorePressed)
                    }
                    .accessibilityIdentifier("RestoreButton")
                } else {
                    editToolbarButton {
                        store.send(.editPressed)
                    }
                }
            }
        }
    }
}

// MARK: Previews

#if DEBUG
/// A `TimeProvider` for previews.
///
class PreviewTimeProvider: TimeProvider {
    /// A fixed date to use for previews.
    var fixedDate: Date

    var presentTime: Date {
        fixedDate
    }

    init(
        fixedDate: Date = .init(
            timeIntervalSinceReferenceDate: 1_695_000_011
        )
    ) {
        self.fixedDate = fixedDate
    }

    func timeSince(_ date: Date) -> TimeInterval {
        presentTime.timeIntervalSince(date)
    }
}

struct ViewItemView_Previews: PreviewProvider {
    static var cipher = CipherView.fixture(
        attachments: [
            .fixture(
                fileName: "selfieWithACat.png",
                id: "1",
                sizeName: "11.2 MB"
            ),
            .fixture(
                fileName: "selfieWithAPotato.png",
                id: "2",
                sizeName: "18.7 MB"
            ),
        ],
        id: "123",
        login: .fixture(),
        type: .login,
        viewPassword: false
    )

    static var cardState: CipherItemState {
        var state = CipherItemState(
            existing: cipher,
            hasPremium: true
        )!
        state.type = CipherType.card
        state.isMasterPasswordRePromptOn = true
        state.name = "Points ALL Day"
        state.notes = "Why are we so consumption focused?"
        state.cardItemState = CardItemState(
            brand: .custom(.americanExpress),
            cardholderName: "Bitwarden User",
            cardNumber: "123456789012345",
            cardSecurityCode: "123",
            expirationMonth: .custom(.feb),
            expirationYear: "3009"
        )
        state.updatedDate = .init(timeIntervalSince1970: 1_695_000_000)
        return state
    }

    static var loginState: CipherItemState {
        var state = CipherItemState(
            existing: cipher,
            hasPremium: true
        )!
        state.customFieldsState.customFields = [
            CustomFieldState(
                linkedIdType: nil,
                name: "Field Name",
                type: .text,
                value: "Value"
            ),
        ]
        state.isMasterPasswordRePromptOn = false
        state.name = "Example"
        state.notes = "This is a long note so that it goes to the next line!"
        state.loginState.fido2Credentials = [
            .fixture(creationDate: Date(timeIntervalSince1970: 1_710_494_110)),
        ]
        state.loginState.password = "Password1!"
        state.updatedDate = .init(timeIntervalSince1970: 1_695_000_000)
        state.loginState.uris = [
            UriState(matchType: .custom(.startsWith), uri: "https://www.example.com"),
            UriState(matchType: .custom(.startsWith), uri: "https://www.example.com/account/login"),
        ]
        state.loginState.totpState = .init(
            authKeyModel: .init(authenticatorKey: "JBSWY3DPEHPK3PXP"),
            codeModel: .init(
                code: "032823",
                codeGenerationDate: .init(timeIntervalSinceReferenceDate: 1_695_000_000),
                period: 30
            )
        )
        state.loginState.username = "email@example.com"
        return state
    }

    static var previews: some View {
        NavigationView {
            ViewItemView(
                store: Store(
                    processor: StateProcessor(
                        state: ViewItemState(
                            loadingState: .loading(nil)
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider(
                    fixedDate: Date(
                        timeIntervalSinceReferenceDate: .init(
                            1_695_000_000
                        )
                    )
                )
            )
        }
        .previewDisplayName("Loading")

        cardPreview

        loginPreview
    }

    @ViewBuilder static var cardPreview: some View {
        NavigationView {
            ViewItemView(
                store: Store(
                    processor: StateProcessor(
                        state: ViewItemState(
                            loadingState: .data(cardState)
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider(
                    fixedDate: Date(
                        timeIntervalSinceReferenceDate: .init(
                            1_695_000_000
                        )
                    )
                )
            )
        }
        .previewDisplayName("Card")
    }

    @ViewBuilder static var loginPreview: some View {
        NavigationView {
            ViewItemView(
                store: Store(
                    processor: StateProcessor(
                        state: ViewItemState(
                            loadingState: .data(loginState)
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider(
                    fixedDate: Date(
                        timeIntervalSinceReferenceDate: .init(
                            1_695_000_011
                        )
                    )
                )
            )
        }
        .previewDisplayName("Login")
    }
}
#endif
