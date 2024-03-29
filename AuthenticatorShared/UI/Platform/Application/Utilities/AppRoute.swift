/// A top level route from the initial screen of the app to anywhere in the app.
///
public enum AppRoute: Equatable {
    case onboarding
}

public enum AppEvent: Equatable {
    /// When the app has started.
    case didStart
}
