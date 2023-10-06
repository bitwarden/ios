@testable import BitwardenShared

class MockAppSettingsStore: AppSettingsStore {
    var appId: String?
    var rememberedEmail: String?
}
