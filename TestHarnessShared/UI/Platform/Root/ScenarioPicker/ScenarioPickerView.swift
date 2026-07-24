import BitwardenKit
import SwiftUI

/// A view that displays a list of test scenarios available in the test harness.
///
struct ScenarioPickerView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<ScenarioPickerState, ScenarioPickerAction, ScenarioPickerEffect>

    // MARK: View

    var body: some View {
        content
            .navigationTitle(store.state.title)
            .navigationBarTitleDisplayMode(.large)
    }

    // MARK: Private Views

    /// The main content view.
    private var content: some View {
        List {
            ForEach(ScenarioSection.allCases, id: \.self) { section in
                let scenarios = store.state.scenarios.filter { $0.section == section }
                if !scenarios.isEmpty {
                    Section {
                        ForEach(scenarios) { scenario in
                            scenarioRow(scenario)
                        }
                    } header: {
                        Text(section.title)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    /// A row displaying a single scenario.
    private func scenarioRow(_ scenario: ScenarioItem) -> some View {
        Button {
            store.send(.scenarioTapped(scenario))
        } label: {
            HStack {
                Text(scenario.title)
                    .styleGuide(.body)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityIdentifier({
            switch scenario.title {
            case Localizations.cardAutofillForm: "ScenarioButton_CardForm"
            case Localizations.createAccountForm: "ScenarioButton_CreateAccountForm"
            case Localizations.fileShare: "ScenarioButton_FileShare"
            case Localizations.managePasskeys: "ScenarioButton_ManagePasskeys"
            case Localizations.passkeyAutofill: "ScenarioButton_Passkey"
            case Localizations.registerPasskey: "ScenarioButton_RegisterPasskey"
            case Localizations.simpleLoginForm: "ScenarioButton_LoginForm"
            case Localizations.totpAutofillForm: "ScenarioButton_TOTPForm"
            case Localizations.usePasskey: "ScenarioButton_UsePasskey"
            default: "ScenarioButton_\(scenario.title)"
            }
        }())
        .foregroundColor(.primary)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationView {
        ScenarioPickerView(store: Store(processor: StateProcessor(state: ScenarioPickerState())))
    }
}
#endif
