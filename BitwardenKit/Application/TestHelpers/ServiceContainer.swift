import BitwardenKit
import BitwardenKitMocks

/// The services provided by the test `ServiceContainer`.
///
typealias Services = HasConfigService
    & HasEnvironmentService
    & HasErrorReportBuilder
    & HasErrorReporter
    & HasTimeProvider

/// A service container used for testing processors within `BitwardenKitTests`.
///
class ServiceContainer: Services {
    let configService: ConfigService
    let errorReportBuilder: any ErrorReportBuilder
    let environmentService: EnvironmentService
    let errorReporter: ErrorReporter
    let timeProvider: TimeProvider

    required init(
        configService: ConfigService,
        errorReportBuilder: ErrorReportBuilder,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        timeProvider: TimeProvider,
    ) {
        self.configService = configService
        self.errorReportBuilder = errorReportBuilder
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.timeProvider = timeProvider
    }
}

extension ServiceContainer {
    static func withMocks(
        configService: ConfigService = MockConfigService(),
        errorReportBuilder: ErrorReportBuilder = MockErrorReportBuilder(),
        environmentService: EnvironmentService = MockEnvironmentService(),
        errorReporter: ErrorReporter = MockErrorReporter(),
        timeProvider: TimeProvider = MockTimeProvider(.currentTime),
    ) -> ServiceContainer {
        self.init(
            configService: configService,
            errorReportBuilder: errorReportBuilder,
            environmentService: environmentService,
            errorReporter: errorReporter,
            timeProvider: timeProvider,
        )
    }
}
