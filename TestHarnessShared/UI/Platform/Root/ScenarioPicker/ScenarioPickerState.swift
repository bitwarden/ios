import Foundation

/// A scenario that can be selected in the test harness.
///
struct ScenarioItem: Equatable, Identifiable {
    // MARK: Properties

    /// The unique identifier for the scenario.
    let id: String

    /// The display title for the scenario.
    let title: String

    /// The route to navigate to when this scenario is selected.
    let route: RootRoute?

    // MARK: Initialization

    /// Initialize a `ScenarioItem`.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the scenario.
    ///   - title: The display title for the scenario.
    ///   - route: The route to navigate to when this scenario is selected. Nil if not yet implemented.
    ///
    init(id: String, title: String, route: RootRoute?) {
        self.id = id
        self.title = title
        self.route = route
    }
}

/// The state for the scenario picker screen.
///
struct ScenarioPickerState: Equatable {
    // MARK: Properties

    /// The title of the screen.
    var title: String = "Test Harness"

    /// The available test scenarios.
    var scenarios: [ScenarioItem] = [
        ScenarioItem(id: "simpleLoginForm", title: "Simple Login Form", route: .simpleLoginForm),
        ScenarioItem(id: "passkeyAutofill", title: "Passkey Autofill", route: nil),
        ScenarioItem(id: "createPasskey", title: "Create Passkey", route: nil),
    ]
}
