import BitwardenKit
import Combine

/// The processor for the date field picker showcase screen.
///
class DateFieldPickerShowcaseProcessor: StateProcessor<
    DateFieldPickerShowcaseState,
    DateFieldPickerShowcaseAction,
    DateFieldPickerShowcaseEffect,
> {
    // MARK: Types

    typealias Services = HasErrorReporter

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    // MARK: Initialization

    /// Initialize a `DateFieldPickerShowcaseProcessor`.
    ///
    /// - Parameter coordinator: The coordinator that handles navigation.
    ///
    init(coordinator: AnyCoordinator<RootRoute, Void>) {
        self.coordinator = coordinator
        super.init(state: DateFieldPickerShowcaseState())
    }

    // MARK: Methods

    override func receive(_ action: DateFieldPickerShowcaseAction) {
        switch action {
        case let .dateChanged(newValue):
            state.selectedDate = newValue
        }
    }
}
