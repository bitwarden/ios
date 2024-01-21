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
                BitwardenTextField(
                    title: field.name,
                    text: store.binding(
                        get: { _ in field.value ?? "" },
                        send: { .customFieldChanged($0, index: index) }
                    )
                ) {
                    Menu {
                        Button(Localizations.edit) {
                            withAnimation {
                                store.send(.editCustomFieldNamePressed(index: index))
                            }
                        }

                        Button(Localizations.moveUp) {
                            withAnimation {
                                store.send(.moveUpCustomFieldPressed(index: index))
                            }
                        }

                        Button(Localizations.moveDown) {
                            withAnimation {
                                store.send(.moveDownCustomFieldPressed(index: index))
                            }
                        }

                        Button(Localizations.remove, role: .destructive) {
                            withAnimation {
                                store.send(.removeCustomFieldPressed(index: index))
                            }
                        }
                    } label: {
                        Asset.Images.gear.swiftUIImage
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                }
                .textFieldConfiguration(.url)
            }

            Button(Localizations.newCustomField) {
                store.send(.newCustomFieldPressed)
            }
            .buttonStyle(.tertiary())
        }
    }
}

#Preview {
    AddEditCustomFieldsView(
        store: Store(
            processor: StateProcessor(
                state: .init()
            )
        )
    )
}
