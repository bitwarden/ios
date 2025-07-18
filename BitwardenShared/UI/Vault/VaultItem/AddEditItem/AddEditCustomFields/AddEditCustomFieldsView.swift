import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - AddEditCustomFieldsView

/// A custom fields view for displaying custom fields for vault items.
struct AddEditCustomFieldsView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AddEditCustomFieldsState, AddEditCustomFieldsAction, Void>

    var body: some View {
        SectionView(Localizations.customFields, contentSpacing: 8) {
            ForEachIndexed(store.state.customFields) { index, field in
                switch field.type {
                case .text:
                    BitwardenTextField(
                        title: field.name,
                        text: store.binding(
                            get: { _ in field.value ?? "" },
                            send: { .customFieldChanged($0, index: index) }
                        )
                    ) {
                        menuOptions(index: index)
                    }
                case .hidden:
                    BitwardenTextField(
                        title: field.name,
                        text: store.binding(
                            get: { _ in field.value ?? "" },
                            send: { .customFieldChanged($0, index: index) }
                        ),
                        passwordVisibilityAccessibilityId: "HiddenCustomFieldShowValueButton",
                        canViewPassword: true,
                        isPasswordVisible: store.binding(
                            get: { _ in field.isPasswordVisible },
                            send: { flag in
                                AddEditCustomFieldsAction.togglePasswordVisibilityChanged(flag, index)
                            }
                        )
                    ) {
                        menuOptions(index: index)
                    }
                    .textFieldConfiguration(.password)
                case .boolean:
                    BitwardenToggle(isOn: store.binding(
                        get: { _ in field.booleanValue },
                        send: { flag in
                            AddEditCustomFieldsAction.booleanFieldChanged(flag, index)
                        }
                    )) {
                        HStack(spacing: 8) {
                            Text(field.name ?? "")

                            menuOptions(index: index, isInFieldLabel: true)
                                .buttonStyle(.fieldLabelIcon)
                        }
                    }
                    .contentBlock()
                case .linked:
                    BitwardenField(title: field.name ?? "") {
                        Menu {
                            Picker(selection:
                                store.binding(
                                    get: { state in
                                        if let idType = field.linkedIdType ??
                                            LinkedIdType.getLinkedIdType(for: state.cipherType).first {
                                            return idType
                                        } else {
                                            assertionFailure("The default LinkedIdType for the customField " +
                                                "should have been set when the user creates linked custom fields.")
                                            return .cardBrand
                                        }
                                    },
                                    send: { idType in
                                        AddEditCustomFieldsAction.selectedLinkedIdType(index, idType)
                                    }
                                )
                            ) {
                                ForEach(LinkedIdType.getLinkedIdType(for: store.state.cipherType)) { idType in
                                    Text(idType.localizedName)
                                        .tag(idType)
                                }
                            } label: {
                                EmptyView()
                            }
                        } label: {
                            Text(field.linkedIdType?.localizedName ?? "")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .styleGuide(.body)
                                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                        }
                    } accessoryContent: {
                        menuOptions(index: index)
                    }
                }
            }

            Button(Localizations.newCustomField) {
                store.send(.newCustomFieldPressed)
            }
            .buttonStyle(.secondary())
            .accessibilityIdentifier("NewCustomFieldButton")
        }
    }

    func menuOptions(index: Int, isInFieldLabel: Bool = false) -> some View {
        Menu {
            Button(Localizations.edit) {
                store.send(.editCustomFieldNamePressed(index: index))
            }

            Button(Localizations.moveUp) {
                store.send(.moveUpCustomFieldPressed(index: index))
            }

            Button(Localizations.moveDown) {
                store.send(.moveDownCustomFieldPressed(index: index))
            }

            Button(Localizations.remove, role: .destructive) {
                store.send(.removeCustomFieldPressed(index: index))
            }
        } label: {
            Group {
                if isInFieldLabel {
                    Asset.Images.cog16.swiftUIImage
                        .imageStyle(.accessoryIcon16(color: SharedAsset.Colors.textInteraction.swiftUIColor))
                } else {
                    Asset.Images.cog24.swiftUIImage
                        .imageStyle(.accessoryIcon24)
                }
            }
            .accessibilityLabel(Localizations.options)
        }
    }
}

#if DEBUG
struct AddEditCustomFieldsView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditCustomFieldsView(
            store: Store(
                processor: StateProcessor(
                    state: AddEditCustomFieldsState(
                        cipherType: .identity,
                        customFields: [
                            CustomFieldState(
                                linkedIdType: nil,
                                name: "Custom text",
                                type: .text,
                                value: "value goes here"
                            ),
                            CustomFieldState(
                                linkedIdType: nil,
                                name: "Custom text",
                                type: .hidden,
                                value: "value goes here"
                            ),
                            CustomFieldState(
                                linkedIdType: nil,
                                name: "Custom boolean",
                                type: .boolean
                            ),
                            CustomFieldState(
                                linkedIdType: .identityFirstName,
                                name: "Custom linked field",
                                type: .linked
                            ),
                        ]
                    )
                )
            )
        )
        .padding(16)
        .background(
            SharedAsset.Colors.backgroundPrimary.swiftUIColor
                .ignoresSafeArea()
        )
    }
}
#endif
