import Foundation

// MARK: - E2EConfigurationError

/// The reasons the end-to-end configuration is rejected.
///
enum E2EConfigurationError: LocalizedError, CustomStringConvertible, Equatable {
    /// The host Mac has a debug environment file, which the app reads before the launch argument.
    case debugEnvironmentFilePresent(path: String)

    /// A variable has a value that isn't allowed.
    case invalidValue(variable: String, reason: String)

    /// A required variable isn't set.
    case missingValue(variable: String)

    var description: String {
        switch self {
        case let .debugEnvironmentFilePresent(path):
            "\(path) exists and overrides the server the app connects to. Remove it to run the end-to-end tests."
        case let .invalidValue(variable, reason):
            "\(variable) \(reason)."
        case let .missingValue(variable):
            "\(variable) isn't set. See the End-to-End UI Tests section of Docs/Testing.md."
        }
    }

    /// XCTest reports a thrown error by its localized description.
    var errorDescription: String? { description }
}

// MARK: - E2EConfiguration

/// The values a run of the end-to-end suite needs, read from the test runner's environment and,
/// for any variable missing there, from the gitignored `.e2e.env` file. Its descriptions never
/// include the server, the seeder or the credentials: test logs are public.
///
struct E2EConfiguration {
    // MARK: Types

    /// The environment variables the configuration is read from.
    ///
    enum Variable {
        static let seederPassword = "BW_SEEDER_PASSWORD"
        static let seederSelfHosted = "BW_SEEDER_SELF_HOSTED"
        static let seederUsername = "BW_SEEDER_USERNAME"
        static let seederURL = "BW_SEEDER_URL"
        static let serverURL = "BW_TEST_SERVER_URL"

        static let allCases = [seederPassword, seederSelfHosted, seederUsername, seederURL, serverURL]
    }

    // MARK: Type Properties

    /// The path, relative to the host Mac's home directory, of the file the app reads its debug
    /// environment from. Matches `Constants.DebugLaunchArguments.preAuthEnvironmentFileRelativePath`.
    static let debugEnvironmentFileRelativePath = ".bitwarden/debug-environment.json"

    /// The `.e2e.env` file at the root of the repository this file was compiled from. The
    /// simulator shares the host's file system, so a run started from Xcode can read it.
    static let defaultEnvironmentFileURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent(".e2e.env")

    /// Hosts the suite refuses to run against, including their subdomains.
    static let productionHosts = ["bitwarden.com", "bitwarden.eu"]

    // MARK: Properties

    /// Whether the server under test is self-hosted.
    let isSelfHosted: Bool

    /// The password for the seeder's basic authentication.
    let seederPassword: String

    /// The base URL of the seeder API.
    let seederURL: URL

    /// The username for the seeder's basic authentication.
    let seederUsername: String

    /// The base URL of the server under test.
    let serverURL: URL

    // MARK: Initialization

    /// Reads and validates the configuration.
    ///
    /// - Parameters:
    ///   - environment: The environment variables of the test runner.
    ///   - environmentFileURL: The file that supplies the variables the environment doesn't have.
    ///   - fileManager: The file manager used to look for the debug environment file.
    ///
    init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        environmentFileURL: URL = E2EConfiguration.defaultEnvironmentFileURL,
        fileManager: FileManager = .default,
    ) throws {
        // A variable exported with no value counts as unset.
        var environment = environment.filter { !$0.value.isEmpty }
        // The file is only opened when the environment is incomplete: never in script or CI runs.
        if Variable.allCases.contains(where: { environment[$0] == nil }) {
            environment.merge(Self.variables(inFileAt: environmentFileURL)) { exported, _ in exported }
        }

        serverURL = try Self.url(for: Variable.serverURL, in: environment)
        seederURL = try Self.url(for: Variable.seederURL, in: environment)
        seederUsername = try Self.value(for: Variable.seederUsername, in: environment)
        seederPassword = try Self.value(for: Variable.seederPassword, in: environment)

        let selfHosted = try Self.value(for: Variable.seederSelfHosted, in: environment)
        guard let isSelfHosted = Bool(selfHosted) else {
            throw E2EConfigurationError.invalidValue(
                variable: Variable.seederSelfHosted,
                reason: "must be true or false",
            )
        }
        self.isSelfHosted = isSelfHosted

        if let hostHome = environment["SIMULATOR_HOST_HOME"] {
            let path = URL(fileURLWithPath: hostHome, isDirectory: true)
                .appendingPathComponent(Self.debugEnvironmentFileRelativePath)
                .path
            if fileManager.fileExists(atPath: path) {
                throw E2EConfigurationError.debugEnvironmentFilePresent(path: path)
            }
        }
    }

    // MARK: Private

    /// Returns the `KEY=value` assignments of an environment file, or nothing if it can't be read.
    ///
    private static func variables(inFileAt url: URL) -> [String: String] {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return [:] }
        var variables = [String: String]()
        for line in contents.components(separatedBy: .newlines) {
            let parts = line.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty, !key.hasPrefix("#") else { continue }
            var value = parts[1].trimmingCharacters(in: .whitespaces)
            if let quote = value.first, quote == "\"" || quote == "'", value.count >= 2, value.last == quote {
                value = String(value.dropFirst().dropLast())
            }
            variables[key] = value
        }
        return variables
    }

    /// Returns the https URL of a non-production host stored in a variable.
    ///
    private static func url(for variable: String, in environment: [String: String]) throws -> URL {
        let value = try value(for: variable, in: environment)
        guard let url = URL(string: value), let host = url.host?.lowercased() else {
            throw E2EConfigurationError.invalidValue(variable: variable, reason: "isn't a valid URL")
        }
        guard url.scheme == "https" else {
            throw E2EConfigurationError.invalidValue(variable: variable, reason: "must use https")
        }
        guard !productionHosts.contains(where: { host == $0 || host.hasSuffix(".\($0)") }) else {
            throw E2EConfigurationError.invalidValue(variable: variable, reason: "must not be a production host")
        }
        return url
    }

    /// Returns the non-empty value of a variable.
    ///
    private static func value(for variable: String, in environment: [String: String]) throws -> String {
        guard let value = environment[variable]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            throw E2EConfigurationError.missingValue(variable: variable)
        }
        return value
    }
}

// MARK: - CustomStringConvertible

extension E2EConfiguration: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    var customMirror: Mirror {
        Mirror(self, children: ["description": description])
    }

    var debugDescription: String {
        description
    }

    var description: String {
        "E2EConfiguration(isSelfHosted: \(isSelfHosted))"
    }
}
