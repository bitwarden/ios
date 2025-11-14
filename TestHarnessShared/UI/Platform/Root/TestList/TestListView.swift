import BitwardenKit
import SwiftUI

/// A view that displays a list of test scenarios available in the test harness.
///
struct TestListView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<TestListState, TestListAction, TestListEffect>

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
                Button {
                    store.send(.passwordAutofillTapped)
                } label: {
                    HStack {
                        Text("Password Autofill")
                            .styleGuide(.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)

                Button {
                    store.send(.passkeyAutofillTapped)
                } label: {
                    HStack {
                        Text("Passkey Autofill")
                            .styleGuide(.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)

                Button {
                    store.send(.createPasskeyTapped)
                } label: {
                    HStack {
                        Text("Create Passkey")
                            .styleGuide(.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
            } header: {
                Text("Test Scenarios")
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationView {
        TestListView(store: Store(processor: StateProcessor(state: TestListState())))
    }
}
#endif
