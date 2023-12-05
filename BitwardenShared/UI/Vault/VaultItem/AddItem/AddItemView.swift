import SwiftUI

// MARK: - AddItemView

/// A view that allows the user to add a new item to a vault.
///
struct AddItemView: View {
    // MARK: Private Properties

    /// An object used to open urls in this view.
    @Environment(\.openURL) private var openURL

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AddItemState, AddItemAction, AddItemEffect>

    // MARK: Views

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                itemInformationSection

                miscellaneousSection

                notesSection

                customFieldsSection

                ownershipSection

                saveButton
            }
            .padding(16)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .navigationTitle(Localizations.addItem)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ToolbarButton(asset: Asset.Images.cancel, label: Localizations.cancel) {
                    store.send(.dismissPressed)
                }
            }
        }
    }

    ///  Returns item information section, Default includes `type` and `name`fields and other fields based on
    ///  `state.type`.
    private var itemInformationSection: some View {
        SectionView(Localizations.itemInformation) {
            BitwardenMenuField(
                title: Localizations.type,
                options: CipherType.allCases,
                selection: store.binding(
                    get: \.type,
                    send: AddItemAction.typeChanged
                )
            )

            BitwardenTextField(
                title: Localizations.name,
                text: store.binding(
                    get: \.name,
                    send: AddItemAction.nameChanged
                )
            )

            switch store.state.type {
            case .login:
                AddLoginItemView(
                    store: store.child(
                        state: { $0.addLoginItemState },
                        mapAction: { $0 },
                        mapEffect: { $0 }
                    )
                )
            case .secureNote:
                EmptyView()
            default:
                EmptyView()
            }
        }
    }

    /// The miscellaneous section.
    private var miscellaneousSection: some View {
        SectionView(Localizations.miscellaneous) {
            BitwardenTextField(
                title: Localizations.folder,
                text: store.binding(
                    get: \.folder,
                    send: AddItemAction.folderChanged
                )
            )

            Toggle(Localizations.favorite, isOn: store.binding(
                get: \.isFavoriteOn,
                send: AddItemAction.favoriteChanged
            ))
            .toggleStyle(.bitwarden)

            Toggle(isOn: store.binding(
                get: \.isMasterPasswordRePromptOn,
                send: AddItemAction.masterPasswordRePromptChanged
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

    /// The notes section.
    private var notesSection: some View {
        SectionView(Localizations.notes) {
            BitwardenTextField(
                text: store.binding(
                    get: \.notes,
                    send: AddItemAction.notesChanged
                )
            )
            .accessibilityLabel(Localizations.notes)
        }
    }

    /// The custom fields section.
    private var customFieldsSection: some View {
        SectionView(Localizations.customFields) {
            Button(Localizations.newCustomField) {
                store.send(.newCustomFieldPressed)
            }
            .buttonStyle(.tertiary())
        }
    }

    /// The ownership section.
    private var ownershipSection: some View {
        SectionView(Localizations.ownership) {
            BitwardenTextField(
                title: Localizations.whoOwnsThisItem,
                text: store.binding(
                    get: \.owner,
                    send: AddItemAction.ownerChanged
                )
            )
        }
    }

    /// The save button section.
    private var saveButton: some View {
        AsyncButton(Localizations.save) {
            await store.perform(.savePressed)
        }
        .buttonStyle(.primary())
    }
}

#Preview {
    NavigationView {
        AddItemView(
            store: Store(
                processor: StateProcessor(
                    state: AddItemState(type: .login)
                )
            )
        )
    }
    .previewDisplayName("Add Item")
}
