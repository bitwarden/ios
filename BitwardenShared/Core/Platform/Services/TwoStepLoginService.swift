import Foundation

/// A protocol for a `TwoStepLoginService` which is used by the application to generate a two step login URL.
///
protocol TwoStepLoginService: AnyObject {
    /// Generates the two step login URL.
    ///
    /// - Returns: The two step login URL.
    ///
    func twoStepLoginUrl() -> URL
}

// MARK: - DefaultTwoStepLoginService

/// The default implementation of `TwoStepLoginService`.
///
class DefaultTwoStepLoginService: TwoStepLoginService {
    // MARK: Properties

    /// The service used by the application to manage the environment settings.
    let environmentService: EnvironmentService

    // MARK: Initialization

    /// Creates a new `DefaultTwoStepLoginService`.
    ///
    /// - Parameters:
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///
    init(environmentService: EnvironmentService) {
        self.environmentService = environmentService
    }

    // MARK: Methods

    func twoStepLoginUrl() -> URL {
        environmentService.settingsURL
    }
}
