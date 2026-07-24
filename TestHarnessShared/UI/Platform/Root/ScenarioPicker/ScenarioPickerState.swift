import Foundation

/// A section used to group related scenarios in the scenario picker.
///
enum ScenarioSection: CaseIterable, Hashable {
    /// The remaining, uncategorized scenarios.
    case general

    /// Scenarios that don't fit into a more specific section.
    case other

    /// Scenarios related to passkey registration, autofill, and management.
    case passkeys

    /// The display title for the section header.
    var title: String {
        switch self {
        case .general: Localizations.testScenarios
        case .other: Localizations.other
        case .passkeys: Localizations.passkeys
        }
    }
}

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

    /// The section this scenario belongs to in the scenario picker.
    let section: ScenarioSection
}

/// The state for the scenario picker screen.
///
struct ScenarioPickerState: Equatable {
    // MARK: Private Type Properties

    /// Scenarios that don't belong to a more specific section.
    private static var generalScenarios: [ScenarioItem] {
        var items = [
            ScenarioItem(
                id: "createAccountForm",
                title: Localizations.createAccountForm,
                route: .createAccountForm,
                section: .general,
            ),
            ScenarioItem(
                id: "simpleLoginForm",
                title: Localizations.simpleLoginForm,
                route: .simpleLoginForm,
                section: .general,
            ),
            ScenarioItem(
                id: "totpAutofillForm",
                title: Localizations.totpAutofillForm,
                route: .totpAutofillForm,
                section: .general,
            ),
            ScenarioItem(
                id: "dateFieldPicker",
                title: Localizations.dateFieldPicker,
                route: .dateFieldPickerShowcase,
                section: .general,
            ),
        ]
        if #available(iOS 17, *) {
            items.append(
                ScenarioItem(
                    id: "cardAutofillForm",
                    title: Localizations.cardAutofillForm,
                    route: .cardAutofillForm,
                    section: .general,
                ),
            )
        }
        return items
    }

    /// Passkey-related scenarios, available on iOS 17 and later.
    private static var passkeyScenarios: [ScenarioItem] {
        guard #available(iOS 17, *) else { return [] }
        return [
            ScenarioItem(
                id: "registerPasskey",
                title: Localizations.registerPasskey,
                route: .registerPasskey,
                section: .passkeys,
            ),
            ScenarioItem(
                id: "usePasskey",
                title: Localizations.passkeyAutofill,
                route: .usePasskey,
                section: .passkeys,
            ),
            ScenarioItem(
                id: "managePasskeys",
                title: Localizations.managePasskeys,
                route: .managePasskeys,
                section: .passkeys,
            ),
        ]
    }

    /// Scenarios that don't fit into a more specific section, available on iOS 16 and later.
    private static var otherScenarios: [ScenarioItem] {
        guard #available(iOS 16, *) else { return [] }
        return [
            ScenarioItem(id: "fileShare", title: Localizations.fileShare, route: .fileShare, section: .other),
        ]
    }

    // MARK: Properties

    /// The title of the screen.
    var title: String = Localizations.testHarness

    /// The available test scenarios.
    var scenarios: [ScenarioItem]

    // MARK: Initialization

    init() {
        scenarios = Self.generalScenarios + Self.passkeyScenarios + Self.otherScenarios
    }
}
