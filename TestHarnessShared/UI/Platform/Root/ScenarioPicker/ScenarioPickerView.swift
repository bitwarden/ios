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
            Section {
                ForEach(store.state.scenarios) { scenario in
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
                    .foregroundColor(.primary)
                }
            } header: {
                Text(Localizations.testScenarios)
            }
        }
        .listStyle(.insetGrouped)
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
