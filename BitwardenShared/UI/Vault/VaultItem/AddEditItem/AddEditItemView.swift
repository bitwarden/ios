import SwiftUI

// MARK: - AddEditItemView

/// A view that allows the user to add a new item to a vault.
///
struct AddEditItemView: View {
    // MARK: Private Properties

    /// An object used to open urls in this view.
    @Environment(\.openURL) private var openURL

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AddEditItemState, AddEditItemAction, AddEditItemEffect>

    var body: some View {
        Group {
            switch store.state.configuration {
            case .add:
                addView
            case .existing:
                existing
            }
        }
        .toast(store.binding(
            get: \.toast,
            send: AddEditItemAction.toastShown
        ))
    }

    private var addView: some View {
        content
            .navigationTitle(Localizations.addItem)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ToolbarButton(asset: Asset.Images.cancel, label: Localizations.cancel) {
                        store.send(.dismissPressed)
                    }
                }
            }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                informationSection
                miscellaneousSection
                notesSection
                customSection
                ownershipSection
                saveButton
            }
            .padding(16)
        }
        .background(
            Asset.Colors.backgroundSecondary.swiftUIColor
                .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private var customSection: some View {
        SectionView(Localizations.customFields) {
            Button(Localizations.newCustomField) {
                store.send(.newCustomFieldPressed)
            }
            .buttonStyle(.tertiary())
        }
    }

    private var existing: some View {
        content
            .navigationTitle(Localizations.editItem)
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
    }

    private var informationSection: some View {
        SectionView(Localizations.itemInformation) {
            if case .add = store.state.configuration {
                BitwardenMenuField(
                    title: Localizations.type,
                    options: CipherType.allCases,
                    selection: store.binding(
                        get: \.type,
                        send: AddEditItemAction.typeChanged
                    )
                )
            }

            BitwardenTextField(
                title: Localizations.name,
                text: store.binding(
                    get: \.name,
                    send: AddEditItemAction.nameChanged
                )
            )

            switch store.state.type {
            case .login:
                loginItems
            case .secureNote:
                EmptyView()
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder private var loginItems: some View {
        AddEditLoginItemView(
            store: store.child(
                state: { addEditState in
                    addEditState.loginState
                },
                mapAction: { $0 },
                mapEffect: { $0 }
            )
        )
    }
}

private extension AddEditItemView {
    var miscellaneousSection: some View {
        SectionView(Localizations.miscellaneous) {
            BitwardenTextField(
                title: Localizations.folder,
                text: store.binding(
                    get: \.folder,
                    send: AddEditItemAction.folderChanged
                )
            )

            Toggle(Localizations.favorite, isOn: store.binding(
                get: \.isFavoriteOn,
                send: AddEditItemAction.favoriteChanged
            ))
            .toggleStyle(.bitwarden)

            Toggle(isOn: store.binding(
                get: \.isMasterPasswordRePromptOn,
                send: AddEditItemAction.masterPasswordRePromptChanged
            )) {
                HStack(alignment: .center, spacing: 4) {
                    Text(Localizations.passwordPrompt)
                    Button {
                        openURL(ExternalLinksConstants.protectIndividualItems)
                    } label: {
                        Asset.Images.questionRound.swiftUIImage
                    }
                    .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                    .accessibilityLabel(Localizations.masterPasswordRePromptHelp)
                }
            }
            .toggleStyle(.bitwarden)
        }
    }

    var notesSection: some View {
        SectionView(Localizations.notes) {
            BitwardenTextField(
                text: store.binding(
                    get: \.notes,
                    send: AddEditItemAction.notesChanged
                )
            )
            .accessibilityLabel(Localizations.notes)
        }
    }

    var ownershipSection: some View {
        SectionView(Localizations.ownership) {
            BitwardenTextField(
                title: Localizations.whoOwnsThisItem,
                text: store.binding(
                    get: \.owner,
                    send: AddEditItemAction.ownerChanged
                )
            )
        }
    }

    var saveButton: some View {
        AsyncButton(Localizations.save) {
            await store.perform(.savePressed)
        }
        .buttonStyle(.primary())
    }
}

struct AddEditItemView_Previews: PreviewProvider {
    static var fixedDate: Date {
        .init(timeIntervalSince1970: 1_695_000_000)
    }

    static var previews: some View {
        NavigationView {
            AddEditItemView(
                store: Store(
                    processor: StateProcessor(
                        state: CipherItemState().addEditState
                    )
                )
            )
        }
        .previewDisplayName("Empty Add")

        NavigationView {
            AddEditItemView(
                store: Store(
                    processor: StateProcessor(
                        state: CipherItemState(
                            existing: .init(
                                id: .init(),
                                organizationId: nil,
                                folderId: nil,
                                collectionIds: [],
                                key: .init(),
                                name: "Edit Em",
                                notes: nil,
                                type: .login,
                                login: .init(
                                    username: "EddyEddity",
                                    password: "changerdanger",
                                    passwordRevisionDate: fixedDate,
                                    uris: [
                                        .init(uri: "yahoo.com", match: nil),
                                        .init(uri: "account.yahoo.com", match: nil),
                                    ],
                                    totp: nil,
                                    autofillOnPageLoad: nil
                                ),
                                identity: nil,
                                card: nil,
                                secureNote: nil,
                                favorite: true,
                                reprompt: .none,
                                organizationUseTotp: false,
                                edit: true,
                                viewPassword: true,
                                localData: nil,
                                attachments: nil,
                                fields: nil,
                                passwordHistory: nil,
                                creationDate: fixedDate,
                                deletedDate: nil,
                                revisionDate: fixedDate
                            )
                        )!.addEditState
                    )
                )
            )
        }
        .previewDisplayName("Edit Login")
    }
}
