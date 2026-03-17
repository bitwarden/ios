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
    & HasServerCommunicationConfigClientSingleton

/// A service container used for testing processors within `BitwardenKitTests`.
///
class ServiceContainer: Services {
    let configService: ConfigService
    let environmentService: EnvironmentService
    let errorReportBuilder: any ErrorReportBuilder
    let errorReporter: ErrorReporter
    let flightRecorder: FlightRecorder
    let languageStateService: any LanguageStateService
    let serverCommunicationConfigClientSingleton: ServerCommunicationConfigClientSingleton
    let timeProvider: TimeProvider

    required init(
        configService: ConfigService,
        environmentService: EnvironmentService,
        errorReportBuilder: ErrorReportBuilder,
        errorReporter: ErrorReporter,
        flightRecorder: FlightRecorder,
        languageStateService: LanguageStateService,
        serverCommunicationConfigClientSingleton: ServerCommunicationConfigClientSingleton,
        timeProvider: TimeProvider,
    ) {
        self.configService = configService
        self.errorReportBuilder = errorReportBuilder
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.flightRecorder = flightRecorder
        self.languageStateService = languageStateService
        self.serverCommunicationConfigClientSingleton = serverCommunicationConfigClientSingleton
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
        // swiftlint:disable:next line_length
        serverCommunicationConfigClientSingleton: ServerCommunicationConfigClientSingleton = MockServerCommunicationConfigClientSingleton(),
        timeProvider: TimeProvider = MockTimeProvider(.currentTime),
    ) -> ServiceContainer {
        self.init(
            configService: configService,
            environmentService: environmentService,
            errorReportBuilder: errorReportBuilder,
            errorReporter: errorReporter,
            flightRecorder: flightRecorder,
            languageStateService: languageStateService,
            serverCommunicationConfigClientSingleton: serverCommunicationConfigClientSingleton,
            timeProvider: timeProvider,
        )
    }
}
