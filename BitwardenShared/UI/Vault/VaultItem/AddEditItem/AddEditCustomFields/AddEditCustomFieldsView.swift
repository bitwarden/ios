import BitwardenSdk
import SwiftUI

// MARK: - AddEditCustomFieldsView

/// A custom fields view for displaying custom fields for vault items.
struct AddEditCustomFieldsView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AddEditCustomFieldsState, AddEditCustomFieldsAction, Void>

    var body: some View {
        SectionView(Localizations.customFields) {
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
                    .textFieldConfiguration(.url)
                case .hidden:
                    BitwardenTextField(
                        title: field.name,
                        text: store.binding(
                            get: { _ in field.value ?? "" },
                            send: { .customFieldChanged($0, index: index) }
                        ),
                        canViewPassword: true,
                        isPasswordVisible: store.binding(
                            get: \.customFields[index].isPasswordVisible,
                            send: { flag in
                                AddEditCustomFieldsAction.togglePasswordVisibilityChanged(flag, index)
                            }
                        )
                    ) {
                        menuOptions(index: index)
                    }
                    .textFieldConfiguration(.password)
                case .boolean:
                    HStack(spacing: 16) {
                        Toggle(field.name ?? "", isOn: store.binding(
                            get: \.customFields[index].booleanValue,
                            send: { flag in
                                AddEditCustomFieldsAction.booleanFieldChanged(flag, index)
                            }
                        ))
                        .toggleStyle(.bitwarden)

                        menuOptions(index: index)
                            .buttonStyle(.accessory)
                    }
                    .frame(height: 60)
                case .linked:
                    BitwardenField(title: field.name ?? "") {
                        // BIT-1548
                        Text(field.linkedIdType?.localizedName ?? "")
                            .styleGuide(.body)
                    }
                    accessoryContent: {
                        menuOptions(index: index)
                    }
                }
            }

            Button(Localizations.newCustomField) {
                store.send(.newCustomFieldPressed)
            }
            .buttonStyle(.tertiary())
        }
    }

    func menuOptions(index: Int) -> some View {
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
            Asset.Images.gear.swiftUIImage
                .resizable()
                .frame(width: 16, height: 16)
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
            Asset.Colors.backgroundSecondary.swiftUIColor
                .ignoresSafeArea()
        )
    }
}
#endif
