import BitwardenKit
import BitwardenResources
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
        guard let data = store.state.loadingState.data else { return false }
        return data.canAssignToCollection
    }

    /// Whether to show the delete option in the toolbar menu.
    var isDeleteEnabled: Bool {
        store.state.loadingState.data?.canBeDeleted ?? false
    }

    /// Whether the restore option is available.
    /// New permission model from PM-18091
    var isRestoredEnabled: Bool {
        store.state.loadingState.data?.canBeRestored ?? false
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
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea())
        .navigationTitle(store.state.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toast(
            store.binding(
                get: \.toast,
                send: ViewItemAction.toastShown
            ),
            additionalBottomPadding: FloatingActionButton.bottomOffsetPadding
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                closeToolbarButton {
                    store.send(.dismissPressed)
                }
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if isRestoredEnabled {
                    toolbarButton(Localizations.restore) {
                        await store.perform(.restorePressed)
                    }
                    .accessibilityIdentifier("RestoreButton")
                }

                VaultItemManagementMenuView(
                    isCloneEnabled: store.state.canClone,
                    isCollectionsEnabled: isCollectionsEnabled,
                    isDeleteEnabled: isDeleteEnabled,
                    isMoveToOrganizationEnabled: isMoveToOrganizationEnabled,
                    store: store.child(
                        state: { _ in },
                        mapAction: { .morePressed($0) },
                        mapEffect: { _ in .deletePressed }
                    )
                )
            }
        }
        .overlay(alignment: .bottomTrailing) {
            editItemFloatingActionButton(hidden: !store.state.canEdit) {
                store.send(.editPressed)
            }
        }
        .onAppear {
            // GitHub issue #1344: Changed from `.task` to `.onAppear` because the close button
            // on the navigation bar was consistently shifting position
            // on physical devices running iOS 16.
            Task {
                await store.perform(.appeared)
            }
        }
        .onDisappear {
            store.send(.disappeared)
        }
    }

    // MARK: Private Views

    /// The details of the item. This view wraps all of the different detail views for
    /// the different types of items into one variable, so that the edit button can be
    /// added to all of them at once.
    @ViewBuilder
    private func details(for state: ViewVaultItemState) -> some View {
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
        .padding(.bottom, FloatingActionButton.bottomOffsetPadding)
        .scrollView()
    }
}

// MARK: Previews

#if DEBUG
struct ViewItemView_Previews: PreviewProvider {
    static var cardState: CipherItemState {
        var state = CipherItemState(
            existing: cipher(forType: .card),
            hasPremium: true
        )!
        state.type = CipherType.card
        state.name = "Points ALL Day"
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
            existing: cipher(forType: .login),
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
        state.name = "Example"
        state.notes = "secure note"
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

    static var secureNoteState: CipherItemState {
        var state = CipherItemState(
            existing: cipher(forType: .secureNote),
            hasPremium: true
        )!
        state.notes = "secure note"
        state.type = .secureNote
        return state
    }

    static var sshKeyState: CipherItemState {
        var state = CipherItemState(
            existing: cipher(forType: .sshKey),
            hasPremium: true
        )!
        state.name = "Example"
        state.type = .sshKey
        state.sshKeyState = SSHKeyItemState(
            privateKey: "ajsdfopij1ZXCVZXC12312QW",
            publicKey: "ssh-ed25519 AAAAA/asdjfoiwejrpo23323j23ASdfas",
            keyFingerprint: "SHA-256:2qwer233ADJOIq1adfweqe21321qw"
        )
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

        secureNotePreview

        sshKeyPreview
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

    @ViewBuilder static var secureNotePreview: some View {
        NavigationView {
            ViewItemView(
                store: Store(
                    processor: StateProcessor(
                        state: ViewItemState(
                            loadingState: .data(secureNoteState)
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
        .previewDisplayName("SecureNote")
    }

    @ViewBuilder static var sshKeyPreview: some View {
        NavigationView {
            ViewItemView(
                store: Store(
                    processor: StateProcessor(
                        state: ViewItemState(
                            loadingState: .data(sshKeyState)
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
        .previewDisplayName("SSH Key")
    }

    static func cipher(forType: BitwardenSdk.CipherType = .login) -> CipherView {
        CipherView.fixture(
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
            type: forType,
            viewPassword: false
        )
    }
}
#endif
