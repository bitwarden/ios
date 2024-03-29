import BitwardenSdk
import UIKit

// swiftlint:disable file_length

/// The `ServiceContainer` contains the list of services used by the app. This can be injected into
/// `Coordinator`s throughout the app which build processors. A `Processor` can define which
/// services it needs access to by defining a typealias containing a list of services.
///
/// For example:
///
///     class ExampleProcessor: StateProcessor<ExampleState, ExampleAction, Void> {
///         typealias Services = HasExampleService
///             & HasExampleRepository
///     }
///
public class ServiceContainer: Services { // swiftlint:disable:this type_body_length
    // MARK: Properties

    /// Provides the present time for TOTP Code Calculation.
    let timeProvider: TimeProvider

    // MARK: Initialization

    /// Initialize a `ServiceContainer`.
    ///
    /// - Parameters:
    ///   - timeProvider: Provides the present time for TOTP Code Calculation.
    ///
    init(
        timeProvider: TimeProvider
    ) {
        self.timeProvider = timeProvider
    }

    /// A convenience initializer to initialize the `ServiceContainer` with the default services.
    ///
    public convenience init() {
        let timeProvider = CurrentTime()

        self.init(
            timeProvider: timeProvider
        )
    }
}
