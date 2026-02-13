import BitwardenKit
import BitwardenSdk

final class ServerCommunicationConfigAPIService: ServerCommunicationConfigPlatformApi {
    func acquireCookies(hostname: String) async -> [BitwardenSdk.AcquiredCookie]? {
        nil
    }
}
