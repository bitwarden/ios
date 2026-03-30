/// A protocol for an object that persists the app ID.
///
public protocol AppIDSettingsStore: AnyObject { // sourcery: AutoMockable
    /// The app's unique identifier.
    /// This is used in calls to the server to uniquely identify this application installation,
    /// such as for authorization or registering for push notifications. It is also used
    /// to make sure keychain entries are unique.
    var appID: String? { get set }
}
