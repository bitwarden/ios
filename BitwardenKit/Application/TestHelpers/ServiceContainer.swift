import BitwardenKit
import BitwardenKitMocks

/// The services provided by the test `ServiceContainer`.
///
typealias Services = HasConfigService
    & HasEnvironmentService
    & HasErrorReportBuilder
    & HasErrorReporter
    & HasFlightRecorder
    & HasLanguageStateService
    & HasTimeProvider

/// A service container used for testing processors within `BitwardenKitTests`.
///
class ServiceContainer: Services {
    let configService: ConfigService
    let environmentService: EnvironmentService
    let errorReportBuilder: any ErrorReportBuilder
    let errorReporter: ErrorReporter
    let flightRecorder: FlightRecorder
    let languageStateService: any LanguageStateService
    let timeProvider: TimeProvider

    required init(
        configService: ConfigService,
        environmentService: EnvironmentService,
        errorReportBuilder: ErrorReportBuilder,
        errorReporter: ErrorReporter,
        flightRecorder: FlightRecorder,
        languageStateService: LanguageStateService,
        timeProvider: TimeProvider,
    ) {
        self.configService = configService
        self.errorReportBuilder = errorReportBuilder
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.flightRecorder = flightRecorder
        self.languageStateService = languageStateService
        self.timeProvider = timeProvider
    }
}

extension ServiceContainer {
    static func withMocks(
        configService: ConfigService = MockConfigService(),
        errorReportBuilder: ErrorReportBuilder = MockErrorReportBuilder(),
        environmentService: EnvironmentService = MockEnvironmentService(),
        errorReporter: ErrorReporter = MockErrorReporter(),
        flightRecorder: FlightRecorder = MockFlightRecorder(),
        languageStateService: LanguageStateService = MockLanguageStateService(),
        timeProvider: TimeProvider = MockTimeProvider(.currentTime),
    ) -> ServiceContainer {
        self.init(
            configService: configService,
            environmentService: environmentService,
            errorReportBuilder: errorReportBuilder,
            errorReporter: errorReporter,
            flightRecorder: flightRecorder,
            languageStateService: languageStateService,
            timeProvider: timeProvider,
        )
    }
}
