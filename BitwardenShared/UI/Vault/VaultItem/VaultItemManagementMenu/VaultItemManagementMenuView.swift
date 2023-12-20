import BitwardenSdk
import SwiftUI

// MARK: - VaultItemManagementMenuView

/// A menu view for displaying options for vault management.
struct VaultItemManagementMenuView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<Void, VaultItemManagementMenuAction, VaultItemManagementMenuEffect>

    var body: some View {
        Menu {
            Button {
                store.send(.attachments)
            } label: {
                Text(Localizations.attachments)
                    .styleGuide(.body)
            }

            Button {
                store.send(.clone)
            } label: {
                Text(Localizations.clone)
                    .styleGuide(.body)
            }

            Button {
                store.send(.moveToOrganization)
            } label: {
                Text(Localizations.moveToOrganization)
                    .styleGuide(.body)
            }

            AsyncButton(role: .destructive) {
                await store.perform(.deleteItem)
            } label: {
                Text(Localizations.delete)
                    .styleGuide(.body)
            }
        } label: {
            Image(asset: Asset.Images.verticalKabob, label: Text(Localizations.options))
                .resizable()
                .frame(width: 19, height: 19)
                .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
        }
        .accessibilityLabel(Localizations.options)
    }
}

#Preview {
    VaultItemManagementMenuView(
        store: Store(
            processor: StateProcessor(
                state: ()
            )
        )
    )
}
