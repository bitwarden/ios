import BitwardenKit
import BitwardenKitMocks
import Combine
import Foundation
import TestHelpers

@testable import AuthenticatorShared

class MockStateService: StateService {
    var activeAccountId: String = "localtest"
    var appId: String = "mockAppId"
    var appLanguage: LanguageOption = .default
    var appTheme: AppTheme?
    var clearClipboardValues = [String: ClearClipboardValue]()
    var clearClipboardResult: Result<Void, Error> = .success(())
    var getSecretKeyResult: Result<String, Error> = .success("qwerty")
    var hasSeenWelcomeTutorial: Bool = false
    var flightRecorderData: FlightRecorderData?
    var preAuthServerConfig: ServerConfig?
    var secretKeyValues = [String: String]()
    var serverConfig = [String: ServerConfig]()
    var setSecretKeyResult: Result<Void, Error> = .success(())
    var timeProvider = MockTimeProvider(.currentTime)
    var vaultTimeout = SessionTimeoutValue.never

    lazy var appThemeSubject = CurrentValueSubject<AppTheme, Never>(self.appTheme ?? .default)

    func getActiveAccountId() async -> String {
        activeAccountId
    }

    func getAppTheme() async -> AppTheme {
        appTheme ?? .default
    }

    func getClearClipboardValue(userId: String?) async throws -> ClearClipboardValue {
        try clearClipboardResult.get()
        let userId = try unwrapUserId(userId)
        return clearClipboardValues[userId] ?? .never
    }

    func getFlightRecorderData() async -> FlightRecorderData? {
        flightRecorderData
    }

    func getPreAuthServerConfig() async -> ServerConfig? {
        preAuthServerConfig
    }

    func getServerConfig(userId: String?) async throws -> ServerConfig? {
        let userId = try unwrapUserId(userId)
        return serverConfig[userId]
    }

    func getVaultTimeout() async -> SessionTimeoutValue {
        vaultTimeout
    }

    func setAppTheme(_ appTheme: AppTheme) async {
        self.appTheme = appTheme
    }

    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String?) async throws {
        try clearClipboardResult.get()
        let userId = try unwrapUserId(userId)
        clearClipboardValues[userId] = clearClipboardValue
    }

    func setFlightRecorderData(_ data: FlightRecorderData?) async {
        flightRecorderData = data
    }

    func appThemePublisher() async -> AnyPublisher<AppTheme, Never> {
        appThemeSubject.eraseToAnyPublisher()
    }

    func getSecretKey(userId: String?) async throws -> String? {
        try getSecretKeyResult.get()
    }

    func setPreAuthServerConfig(config: ServerConfig) async {
        preAuthServerConfig = config
    }

    func setSecretKey(_ key: String, userId: String?) async throws {
        try setSecretKeyResult.get()
        secretKeyValues[userId ?? "localtest"] = key
    }

    func setServerConfig(_ config: ServerConfig?, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        serverConfig[userId] = config
    }

    /// Attempts to convert a possible user id into a known account id.
    ///
    /// - Parameter userId: If nil, the active account id is returned. Otherwise, validate the id.
    ///
    func unwrapUserId(_ userId: String?) throws -> String {
        if let userId {
            return userId
        } else {
            throw BitwardenTestError.example
        }
    }
}
