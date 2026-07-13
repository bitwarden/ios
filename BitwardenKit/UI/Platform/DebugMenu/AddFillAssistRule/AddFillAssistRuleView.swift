import SwiftUI

// MARK: - AddFillAssistRuleView

/// A view that allows adding a Fill Assist rule to the active account's cached rules, for
/// testing Fill Assist against custom pages.
///
struct AddFillAssistRuleView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AddFillAssistRuleState, AddFillAssistRuleAction, AddFillAssistRuleEffect>

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            BitwardenTextField(
                title: "Domain",
                text: store.binding(
                    get: \.domain,
                    send: AddFillAssistRuleAction.domainChanged,
                ),
                footer: "The bare host to match, e.g. \"bitwarden.com\"",
                accessibilityIdentifier: "AddFillAssistRuleDomainField",
            )
            .textFieldConfiguration(.organizationIdentifier)

            BitwardenTextField(
                title: "Username field id",
                text: store.binding(
                    get: \.usernameFieldId,
                    send: AddFillAssistRuleAction.usernameFieldIdChanged,
                ),
                footer: "The username field's \"id\" attribute, e.g. \"username\"",
                accessibilityIdentifier: "AddFillAssistRuleUsernameIdField",
            )
            .textFieldConfiguration(.organizationIdentifier)

            BitwardenTextField(
                title: "Password field id",
                text: store.binding(
                    get: \.passwordFieldId,
                    send: AddFillAssistRuleAction.passwordFieldIdChanged,
                ),
                footer: "The password field's \"id\" attribute, e.g. \"password\"",
                accessibilityIdentifier: "AddFillAssistRulePasswordIdField",
            )
            .textFieldConfiguration(.organizationIdentifier)
        }
        .navigationBar(title: "Add Fill Assist Rule", titleDisplayMode: .inline)
        .scrollView()
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }

            saveToolbarItem {
                await store.perform(.saveTapped)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    AddFillAssistRuleView(store: Store(processor: StateProcessor(state: AddFillAssistRuleState())))
        .navStackWrapped
}
#endif
