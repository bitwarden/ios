import BitwardenKit
import BitwardenSdk
import Combine
import Foundation

/// A service that bridges server communication configuration requests from the SDK,
/// allowing the app to acquire cookies on behalf of the SDK and deliver the results back.
public protocol ServerCommunicationConfigAPIService: ServerCommunicationConfigPlatformApi {
    /// Returns a publisher that emits the hostname whenever `acquireCookies(hostname:)` is called,
    /// before the continuation is awaited. Starts with `nil`.
    func acquireCookiesPublisher() async -> AnyPublisher<String?, Never>

    /// Parses cookies from the given callback URL and resumes the pending continuation.
    ///
    /// Query items whose name is `"d"` are excluded from the result. If `callbackURL` is `nil`
    /// (e.g. the web auth session was cancelled), the continuation is resumed with `nil`.
    ///
    /// - Parameter callbackURL: The callback URL returned by the web auth session, or `nil`.
    func cookiesAcquired(from callbackURL: URL?) async
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

    func cookiesAcquired(from callbackURL: URL?) async {
        defer { acquireCookiesContinuation = nil }

        guard callbackURL?.absoluteString.starts(with: BitwardenDeepLinkConstants.ssoCookieVendor) == true else {
            acquireCookiesContinuation?.resume(with: .success(nil))
            return
        }

        let components = callbackURL.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let cookies = components?.queryItems?.compactMap { item -> AcquiredCookie? in
            // Exclude query items whose name is "d", which are the only ones that are not cookies values.
            guard let value = item.value, item.name != "d" else { return nil }
            return AcquiredCookie(name: item.name, value: value)
        }

        acquireCookiesContinuation?.resume(with: .success(cookies))
    }
}
