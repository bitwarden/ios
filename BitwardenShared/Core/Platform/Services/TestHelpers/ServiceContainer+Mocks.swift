import Networking

@testable import BitwardenShared

extension ServiceContainer {
    static func withMocks(
        appSettingsStore: AppSettingsStore = MockAppSettingsStore(),
        httpClient: HTTPClient = MockHTTPClient()
    ) -> ServiceContainer {
        ServiceContainer(
            apiService: APIService(client: httpClient),
            appSettingsStore: appSettingsStore
        )
    }
}
