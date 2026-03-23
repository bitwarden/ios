import Foundation

/// A service that manages getting and creating the app's ID.
///
actor AppIDService {
    // MARK: Properties

    /// The app settings store used to persist app values.
    let appSettingStore: AppSettingsStore

    // MARK: Initialization

    /// Initialize an `AppIDService`.
    ///
    /// - Parameter appSettingStore: The app settings store used to persist app values.
    ///
    init(appSettingStore: AppSettingsStore) {
        self.appSettingStore = appSettingStore
    }

    // MARK: Methods

    /// Returns the app's ID if it exists or creates a new one.
    ///
    /// - Returns: The app's ID.
    ///
    func getOrCreateAppID() -> String {
        if let appId = appSettingStore.appId {
            return appId
        } else {
            let appId = UUID().uuidString
            appSettingStore.appId = appId
            return appId
        }
    }
}
