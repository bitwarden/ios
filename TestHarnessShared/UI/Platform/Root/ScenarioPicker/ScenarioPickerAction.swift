import Foundation

/// Actions that can be processed by a `ScenarioPickerProcessor`.
///
enum ScenarioPickerAction: Equatable {
    /// A test scenario was tapped.
    ///
    /// - Parameter scenario: The scenario that was tapped.
    case scenarioTapped(ScenarioItem)
}
