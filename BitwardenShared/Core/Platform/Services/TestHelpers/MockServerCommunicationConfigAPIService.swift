import BitwardenSdk
import Combine

@testable import BitwardenShared

final class MockServerCommunicationConfigAPIService: ServerCommunicationConfigAPIService {
    var acquireCookiesCalledHostname: String?
    var acquireCookiesResult: [BitwardenSdk.AcquiredCookie]?
    var acquireCookiesSubject = CurrentValueSubject<String?, Never>(nil)
    var cookiesAcquiredResult: Result<[BitwardenSdk.AcquiredCookie]?, Error>?

    func acquireCookies(hostname: String) async -> [BitwardenSdk.AcquiredCookie]? {
        acquireCookiesCalledHostname = hostname
        return acquireCookiesResult
    }

    func acquireCookiesPublisher() async -> AnyPublisher<String?, Never> {
        acquireCookiesSubject.eraseToAnyPublisher()
    }

    func cookiesAcquired(cookies: Result<[BitwardenSdk.AcquiredCookie]?, Error>) async {
        cookiesAcquiredResult = cookies
    }
}
