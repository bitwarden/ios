/// A top level route from the initial screen of the app to anywhere in the app.
///
public enum AppRoute: Equatable {
    /// A route to the debug menu.
    case debugMenu

    /// A route to the tab interface.
    case tab(TabRoute)
}

public enum AppEvent: Equatable {
    /// When the app has started.
    case didStart

    /// When the user returns to the app and their vault timeout has passed.
    case vaultTimeout
}
