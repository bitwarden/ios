import Foundation

@testable import BitwardenShared

extension EnvironmentUrlData {
    static func fixture(
        api: URL? = nil,
        base: URL? = URL(string: "https://vault.bitwarden.com"),
        events: URL? = nil,
        identity: URL? = nil,
        icons: URL? = nil,
        notifications: URL? = nil,
        webVault: URL? = nil
    ) -> EnvironmentUrlData {
        EnvironmentUrlData(
            api: api,
            base: base,
            events: events,
            identity: identity,
            icons: icons,
            notifications: notifications,
            webVault: webVault
        )
    }
}
