import BitwardenKit
import BitwardenSdk
import Combine

/// A service that bridges server communication configuration requests from the SDK,
/// allowing the app to acquire cookies on behalf of the SDK and deliver the results back.
public  protocol ServerCommunicationConfigAPIService: ServerCommunicationConfigPlatformApi {
    /// Returns a publisher that emits the hostname whenever `acquireCookies(hostname:)` is called,
    /// before the continuation is awaited. Starts with `nil`.
    func acquireCookiesPublisher() async -> AnyPublisher<String?, Never>

    /// Resumes the pending continuation with the result of a cookie acquisition.
    ///
    /// - Parameter cookies: The result of the cookie acquisition, containing the acquired cookies
    ///   or an error if acquisition failed.
    func cookiesAcquired(cookies: Result<[BitwardenSdk.AcquiredCookie]?, Error>) async
}

/// Default implementation of `ServerCommunicationConfigAPIService`.
final actor DefaultServerCommunicationConfigAPIService: ServerCommunicationConfigAPIService {
    /// Continuation when acquiring cookies.
    var acquireCookiesContinuation: CheckedContinuation<[AcquiredCookie]?, Error>?

    /// Subject that backs the `acquireCookiesPublisher`.
    let acquireCookiesSubject = CurrentValueSubject<String?, Never>(nil)

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// Initializes a `ServerCommunicationConfigAPIService`.
    /// - Parameter errorReporter: The service used by the application to report non-fatal errors.
    init(errorReporter: ErrorReporter) {
        self.errorReporter = errorReporter
    }

    func acquireCookies(hostname: String) async -> [BitwardenSdk.AcquiredCookie]? {
        acquireCookiesSubject.send(hostname)
        do {
            return try await withCheckedThrowingContinuation { continuation in
                self.acquireCookiesContinuation = continuation
            }
        } catch {
            errorReporter.log(error: error)
            return nil
        }
    }

    func acquireCookiesPublisher() async -> AnyPublisher<String?, Never> {
        acquireCookiesSubject.eraseToAnyPublisher()
    }

    func cookiesAcquired(cookies: Result<[BitwardenSdk.AcquiredCookie]?, Error>) async {
        acquireCookiesContinuation?.resume(with: cookies)
    }
}
