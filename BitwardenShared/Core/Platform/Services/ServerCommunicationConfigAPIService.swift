import BitwardenKit
import BitwardenSdk
import Combine

/// A service that bridges server communication configuration requests from the SDK,
/// allowing the app to acquire cookies on behalf of the SDK and deliver the results back.
public protocol ServerCommunicationConfigAPIService: ServerCommunicationConfigPlatformApi {
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

    /// Helper to know about the app context.
    let appContextHelper: AppContextHelper

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The service used to subscribe to notification center events.
    let notificationCenterService: NotificationCenterService

    /// Initializes a `ServerCommunicationConfigAPIService`.
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - notificationCenterService: The service used to subscribe to notification center events.
    init(
        appContextHelper: AppContextHelper,
        errorReporter: ErrorReporter,
        notificationCenterService: NotificationCenterService,
    ) {
        self.appContextHelper = appContextHelper
        self.errorReporter = errorReporter
        self.notificationCenterService = notificationCenterService
    }

    func acquireCookies(hostname: String) async -> [BitwardenSdk.AcquiredCookie]? {
        // Drop concurrent calls: an acquisition is already in flight.
        guard acquireCookiesContinuation == nil else {
            return nil
        }

        if appContextHelper.appContext == .mainApp {
            // we only check if it's on foreground on the main app, as most times the extension just closes
            // when sending the browser to background so practically we shouldn't have requests
            // on extensions backgrounded.
            let isInForeground = await notificationCenterService.isInForegroundPublisher().first(where: { _ in true })
            guard isInForeground == true else {
                return nil
            }
        }

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
        acquireCookiesContinuation = nil
    }
}
