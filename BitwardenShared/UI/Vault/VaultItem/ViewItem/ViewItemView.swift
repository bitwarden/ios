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
            if let viewState = state.viewState {
                details(for: viewState)
            }
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
    private func details(for state: ViewVaultItemState) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ViewItemDetailView(
                    store: store.child(
                        state: { _ in state },
                        mapAction: { $0 },
                        mapEffect: { $0 }
                    )
                )
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

struct ViewItemDetailView: View {
    /// The `Store` for this view.
    @ObservedObject var store: Store<ViewVaultItemState, ViewItemAction, ViewItemEffect>

    var body: some View {
        itemInformationSection

        if !store.state.notes.isEmpty {
            notesSection
        }

        if !store.state.customFields.isEmpty {
            customFieldsSection
        }

        updatedDate
    }

    var itemInformationSection: some View {
        SectionView(Localizations.itemInformation, contentSpacing: 12) {
            BitwardenTextValueField(title: Localizations.name, value: store.state.name)

            if store.state.type == .login, let loginState = store.state.loginState {
                ViewLoginItemView(
                    store: store.child(
                        state: { _ in loginState },
                        mapAction: { $0 },
                        mapEffect: { $0 }
                    )
                )
            }
        }
    }

    var notesSection: some View {
        SectionView(Localizations.notes) {
            BitwardenTextValueField(value: store.state.notes)
        }
    }

    var customFieldsSection: some View {
        SectionView(Localizations.customFields) {
            ForEach(store.state.customFields, id: \.self) { customField in
                BitwardenField(title: customField.name) {
                    switch customField.type {
                    case .boolean:
                        let image = customField.booleanValue
                            ? Asset.Images.checkSquare.swiftUIImage
                            : Asset.Images.square.swiftUIImage
                        image
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    case .hidden:
                        if let value = customField.value {
                            PasswordText(
                                password: value,
                                isPasswordVisible: customField.isPasswordVisible
                            )
                        }
                    case .text:
                        if let value = customField.value {
                            Text(value)
                        }
                    case .linked:
                        if let linkedIdType = customField.linkedIdType {
                            HStack(spacing: 8) {
                                Asset.Images.link.swiftUIImage
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                                Text(linkedIdType.localizedName)
                            }
                        }
                    }
                } accessoryContent: {
                    if let value = customField.value {
                        switch customField.type {
                        case .hidden:
                            PasswordVisibilityButton(isPasswordVisible: customField.isPasswordVisible) {
                                store.send(.customFieldVisibilityPressed(customField))
                            }
                            Button {
                                store.send(.copyPressed(value: value))
                            } label: {
                                Asset.Images.copy.swiftUIImage
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            }
                        case .text:
                            Button {
                                store.send(.copyPressed(value: value))
                            } label: {
                                Asset.Images.copy.swiftUIImage
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            }
                        case .boolean, .linked:
                            EmptyView()
                        }
                    }
                }
            }
        }
    }

    var updatedDate: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormattedDateTimeView(label: Localizations.dateUpdated, date: store.state.updatedDate)

            //            passwordUpdatedDate()

            // TODO: BIT-1186 Display the password history button here
        }
        .font(.subheadline)
        .multilineTextAlignment(.leading)
        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
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
        key: nil,
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

    static var loginState: CipherItemState {
        var state = CipherItemState(existing: cipher)!
        state.customFields = [
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
        state.loginState.password = "Password1!"
        state.updatedDate = .init(timeIntervalSince1970: 1_695_000_000)
        state.loginState.uris = [
            CipherLoginUriModel(
                match: .startsWith,
                uri: "https://www.example.com"
            ),
            CipherLoginUriModel(
                match: .exact,
                uri: "https://www.example.com/account/login"
            ),
        ]
        state.loginState.username = "email@example.com"
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
                            loadingState: .data(loginState)
                        )
                    )
                )
            )
        }
        .previewDisplayName("Login")
    }
}
#endif
