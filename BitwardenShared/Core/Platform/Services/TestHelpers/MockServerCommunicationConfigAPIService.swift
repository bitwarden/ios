import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

final class MockServerCommunicationConfigAPIService: ServerCommunicationConfigAPIService {
    var acquireCookiesCalledHostname: String?
    var acquireCookiesResult: [BitwardenSdk.AcquiredCookie]?
    var acquireCookiesSubject = CurrentValueSubject<String?, Never>(nil)
    var cookiesAcquiredFromCalled = false
    var cookiesAcquiredFromURL: URL?
    var cookiesAcquiredResult: Result<[BitwardenSdk.AcquiredCookie]?, Error>?

    func acquireCookies(hostname: String) async -> [BitwardenSdk.AcquiredCookie]? {
        acquireCookiesCalledHostname = hostname
        return acquireCookiesResult
    }

    func acquireCookiesPublisher() async -> AnyPublisher<String?, Never> {
        acquireCookiesSubject.eraseToAnyPublisher()
    }

    func cookiesAcquired(from callbackURL: URL?) async {
        cookiesAcquiredFromCalled = true
        cookiesAcquiredFromURL = callbackURL
    }
}
