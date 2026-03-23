import BitwardenKit
import Foundation

/// A service that manages getting and creating the app's ID.
///
actor AppIdService {
    // MARK: Properties

    /// The app settings store used to persist app values.
    let appSettingStore: AppIDSettingsStore

    // MARK: Initialization

    /// Initialize an `AppIdService`.
    ///
    /// - Parameter appSettingStore: The app settings store used to persist app values.
    ///
    init(appSettingStore: AppIDSettingsStore) {
        self.appSettingStore = appSettingStore
    }

    // MARK: Methods

    /// Returns the app's ID if it exists or creates a new one.
    ///
    /// - Returns: The app's ID.
    ///
    func getOrCreateAppId() -> String {
        if let appID = appSettingStore.appID {
            return appID
        } else {
            let appID = UUID().uuidString
            appSettingStore.appID = appID
            return appID
        }
    }
}
