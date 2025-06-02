/// Helper registry to register all app intents preventing to be stripped out by the optimizer in release mode.
enum AppIntentRegistry {
    /// Register all app intents so not to be stripped out by the optimizer.
    static func register() {
        guard #available(iOS 16.0, *) else {
            return
        }
        _ = GeneratePassphraseIntent()
        _ = LockAllAccountsIntent()
        _ = LogoutAllAccountsIntent()
        _ = OpenGeneratorIntent()
    }
}
