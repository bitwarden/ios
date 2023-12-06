import BitwardenSdk
import SwiftUI

// MARK: - ViewItemView

/// A view that displays the contents of a vault item.
struct ViewItemView: View {
    // MARK: Private Properties

    /// An environment variable used to open URLs.
    @Environment(\.openURL) private var openURL

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewItemState, ViewItemAction, ViewItemEffect>

    var body: some View {
        LoadingView(state: store.state.loadingState) { state in
            details(for: state)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    store.send(.morePressed)
                } label: {
                    Asset.Images.verticalKabob.swiftUIImage
                        .resizable()
                        .frame(width: 19, height: 19)
                }
                .accessibilityLabel(Localizations.options)

                Button {
                    store.send(.dismissPressed)
                } label: {
                    Asset.Images.cancel.swiftUIImage
                        .resizable()
                        .frame(width: 19, height: 19)
                }
                .accessibilityLabel(Localizations.close)
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

    // MARK: Private Methods

    /// The details of the item. This view wraps all of the different detail views for
    /// the different types of items into one variable, so that the edit button can be
    /// added to all of them at once.
    @ViewBuilder
    private func details(for state: ViewItemState.ItemTypeState) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                switch state {
                case let .login(loginState):
                    ViewLoginItemView(store: store.child(
                        state: { _ in loginState },
                        mapAction: { $0 },
                        mapEffect: { $0 }
                    ))
                }
            }
            .padding(16)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Localizations.edit) {
                    store.send(.editPressed)
                }
            }
        }
    }
}

// MARK: Previews

#if DEBUG
struct ViewItemView_Previews: PreviewProvider {
    static var cipher = CipherView(
        id: "123",
        organizationId: nil,
        folderId: nil,
        collectionIds: [],
        name: "",
        notes: nil,
        type: .login,
        login: .init(
            username: nil,
            password: nil,
            passwordRevisionDate: nil,
            uris: nil,
            totp: nil,
            autofillOnPageLoad: nil
        ),
        identity: nil,
        card: nil,
        secureNote: nil,
        favorite: false,
        reprompt: .none,
        organizationUseTotp: false,
        edit: false,
        viewPassword: false,
        localData: nil,
        attachments: nil,
        fields: nil,
        passwordHistory: nil,
        creationDate: .now,
        deletedDate: nil,
        revisionDate: .now
    )

    static var loadedState: LoginItemState {
        var state = LoginItemState(cipherView: cipher)!
        state.properties = .init(
            customFields: [
                CustomFieldState(
                    linkedIdType: nil,
                    name: "Field Name",
                    type: .text,
                    value: "Value"
                ),
            ],
            folder: "Folder",
            isFavoriteOn: true,
            isMasterPasswordRePromptOn: false,
            name: "Example",
            notes: "This is a long note so that it goes to the next line!",
            password: "Password1!",
            type: .login,
            updatedDate: .init(timeIntervalSince1970: 1_695_000_000),
            uris: [
                CipherLoginUriModel(
                    match: .startsWith,
                    uri: "https://www.example.com"
                ),
                CipherLoginUriModel(
                    match: .exact,
                    uri: "https://www.example.com/account/login"
                ),
            ],
            username: "email@example.com"
        )
        return state
    }

    static var previews: some View {
        NavigationView {
            ViewItemView(
                store: Store(
                    processor: StateProcessor(
                        state: ViewItemState(
                            loadingState: .loading
                        )
                    )
                )
            )
        }
        .previewDisplayName("Loading")

        NavigationView {
            ViewItemView(
                store: Store(
                    processor: StateProcessor(
                        state: ViewItemState(
                            loadingState: .data(.login(loadedState))
                        )
                    )
                )
            )
        }
        .previewDisplayName("Login")
    }
}
#endif
