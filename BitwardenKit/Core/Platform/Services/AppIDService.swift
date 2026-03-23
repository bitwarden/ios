import Foundation

/// A service that manages getting and creating the app's ID.
///
public actor AppIDService {
    // MARK: Properties

    /// The app settings store used to persist app values.
    let appIDSettingsStore: AppIDSettingsStore

    // MARK: Initialization

    /// Initialize an `AppIDService`.
    ///
    /// - Parameter appIDSettingsStore: The app settings store used to persist app values.
    ///
    public init(appIDSettingsStore: AppIDSettingsStore) {
        self.appIDSettingsStore = appIDSettingsStore
    }

    // MARK: Methods

    /// Returns the app's ID if it exists or creates a new one.
    ///
    /// - Returns: The app's ID.
    ///
    public func getOrCreateAppID() -> String {
        if let appID = appIDSettingsStore.appID {
            return appID
        } else {
            let appID = UUID().uuidString
            appIDSettingsStore.appID = appID
            return appID
        }
    }
}
