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
}

/// The state for the scenario picker screen.
///
struct ScenarioPickerState: Equatable {
    // MARK: Properties

    /// The title of the screen.
    var title: String = Localizations.testHarness

    /// The available test scenarios.
    var scenarios: [ScenarioItem]

    // MARK: Initialization

    init() {
        var items: [ScenarioItem] = [
            ScenarioItem(id: "simpleLoginForm", title: Localizations.simpleLoginForm, route: .simpleLoginForm),
            ScenarioItem(
                id: "dateFieldPicker",
                title: Localizations.dateFieldPicker,
                route: .dateFieldPickerShowcase,
            ),
        ]
        if #available(iOS 17, *) {
            items.append(
                ScenarioItem(id: "cardAutofillForm", title: Localizations.cardAutofillForm, route: .cardAutofillForm),
            )
        }
        items.append(contentsOf: [
            ScenarioItem(id: "passkeyAutofill", title: Localizations.passkeyAutofill, route: nil),
        ])
        scenarios = items
    }
}
