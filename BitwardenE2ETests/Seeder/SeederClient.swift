import Foundation

// MARK: - SeederError

/// The errors thrown by `SeederClient`. None of them carry the seeder's host or credentials.
///
enum SeederError: LocalizedError, CustomStringConvertible {
    /// The request never got a response. Only the error's domain and code are kept, because its
    /// description names the host.
    case requestFailed(method: String, path: String, domain: String, code: Int)

    /// The seeder didn't answer within `E2ETimeouts.seederRequest`.
    case timedOut(method: String, path: String)

    /// The seeder didn't return a unique email for the one requested. Without it the play isn't
    /// tracked, so deleting the play would remove nothing.
    case emailNotMangled(requested: String)

    /// The seeder answered with a status code other than 2xx.
    case unexpectedStatus(method: String, path: String, statusCode: Int, body: String)

    var description: String {
        switch self {
        case let .emailNotMangled(requested):
            "The seeder's mangleMap has no entry for \(requested)."
        case let .requestFailed(method, path, domain, code):
            "Seeder \(method) \(path) failed: \(domain) \(code)."
        case let .timedOut(method, path):
            "Seeder \(method) \(path) didn't answer within \(Int(E2ETimeouts.seederRequest)) seconds."
        case let .unexpectedStatus(method, path, statusCode, body):
            "Seeder \(method) \(path) returned \(statusCode): \(body)"
        }
    }

    /// XCTest reports a thrown error by its localized description.
    var errorDescription: String? { description }
}

// MARK: - SeederClient

/// Creates and removes server data for one test through the seeder API. Everything it creates is
/// tracked under one play ID.
///
/// Requests block the calling thread. Tests are synchronous because XCTest can't stop an `async`
/// test at a failed assertion: the test hangs until its time allowance runs out.
///
final class SeederClient {
    // MARK: Types

    /// The arguments of `SingleUserScene`. The server defaults cover the rest.
    private struct SingleUserArguments: Encodable {
        let email: String
        let password: String
        let emailVerified: Bool
        let premium: Bool
        let selfHosted: Bool
    }

    /// The result of `SingleUserScene`.
    private struct SingleUserResult: Decodable {
        let userId: String
        let decryptedKeyB64: String
    }

    /// The arguments of `UserLoginCipherScene`. The server defaults cover the rest.
    private struct UserLoginCipherArguments: Encodable {
        let userId: String
        let userKeyB64: String
        let name: String
        let username: String
        let password: String
        let uri: String
    }

    /// A scene result the client doesn't read.
    private struct IgnoredResult: Decodable {
        init(from decoder: Decoder) throws {}
    }

    // MARK: Type Properties

    /// The email requested for every seeded user. The seeder replaces it with a unique one.
    private static let requestedEmail = "e2e@example.com"

    // MARK: Properties

    /// The suite's configuration.
    private let configuration: E2EConfiguration

    /// The ID every request is tracked under.
    let playID: String

    /// The session used to perform the requests.
    private let session: URLSession

    // MARK: Initialization

    /// Creates a client for one test.
    ///
    /// - Parameters:
    ///   - configuration: The suite's configuration.
    ///   - playID: The ID every request is tracked under.
    ///
    init(configuration: E2EConfiguration, playID: String = UUID().uuidString) {
        self.configuration = configuration
        self.playID = playID

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.timeoutIntervalForRequest = E2ETimeouts.seederRequest
        session = URLSession(configuration: sessionConfiguration)
    }

    // MARK: Methods

    /// Adds a login item to an account's vault.
    ///
    /// - Parameters:
    ///   - item: The login item to add.
    ///   - account: The account that owns the item.
    ///
    func addLoginItem(_ item: SeededLoginItem, for account: SeededAccount) throws {
        let _: IgnoredResult = try seed(
            template: "UserLoginCipherScene",
            arguments: UserLoginCipherArguments(
                userId: account.userId,
                userKeyB64: account.userKeyB64,
                name: item.name,
                username: item.username,
                password: item.password,
                uri: item.uri,
            ),
        ).result
    }

    /// Creates a free account with a verified email.
    ///
    /// - Returns: The account, with the email and master password to log in with.
    ///
    func createFreeUser() throws -> SeededAccount {
        let password = "E2e-\(UUID().uuidString)"
        let response: SeedResponse<SingleUserResult> = try seed(
            template: "SingleUserScene",
            arguments: SingleUserArguments(
                email: Self.requestedEmail,
                password: password,
                emailVerified: true,
                premium: false,
                selfHosted: configuration.isSelfHosted,
            ),
        )
        guard let email = response.mangleMap?[Self.requestedEmail] ?? nil else {
            throw SeederError.emailNotMangled(requested: Self.requestedEmail)
        }
        return SeededAccount(
            email: email,
            password: password,
            userKeyB64: response.result.decryptedKeyB64,
            userId: response.result.userId,
        )
    }

    /// Removes everything created under this client's play ID.
    ///
    func deletePlayID() throws {
        _ = try send(method: "DELETE", path: "seed/\(playID)", body: nil)
    }

    // MARK: Private

    /// Runs a scene.
    ///
    private func seed<Arguments: Encodable, Result: Decodable>(
        template: String,
        arguments: Arguments,
    ) throws -> SeedResponse<Result> {
        let body = try JSONEncoder().encode(SeedRequest(template: template, arguments: arguments))
        let data = try send(method: "POST", path: "seed", body: body)
        return try JSONDecoder().decode(SeedResponse<Result>.self, from: data)
    }

    /// Performs a request against the seeder and returns the body of a 2xx response.
    ///
    private func send(method: String, path: String, body: Data?) throws -> Data {
        var request = URLRequest(url: configuration.seederURL.appendingPathComponent(path))
        request.httpMethod = method
        request.httpBody = body
        let credentials = Data("\(configuration.seederUsername):\(configuration.seederPassword)".utf8)
        request.setValue("Basic \(credentials.base64EncodedString())", forHTTPHeaderField: "Authorization")
        request.setValue(playID, forHTTPHeaderField: "x-play-id")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let finished = DispatchSemaphore(value: 0)
        var outcome: Result<(Data, URLResponse), Error>?
        session.dataTask(with: request) { data, response, error in
            if let data, let response {
                outcome = .success((data, response))
            } else {
                outcome = .failure(error ?? URLError(.unknown))
            }
            finished.signal()
        }.resume()
        guard finished.wait(timeout: .now() + E2ETimeouts.seederRequest + 5) == .success, let outcome else {
            throw SeederError.timedOut(method: method, path: path)
        }

        let data: Data
        let response: URLResponse
        switch outcome {
        case let .success(success):
            (data, response) = success
        case let .failure(error as NSError):
            throw SeederError.requestFailed(method: method, path: path, domain: error.domain, code: error.code)
        }
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200 ..< 300).contains(statusCode) else {
            throw SeederError.unexpectedStatus(
                method: method,
                path: path,
                statusCode: statusCode,
                body: String(bytes: data, encoding: .utf8) ?? "",
            )
        }
        return data
    }
}
