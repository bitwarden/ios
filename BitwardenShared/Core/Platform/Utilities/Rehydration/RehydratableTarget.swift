/// The target to rehydrate with additional context info.
public enum RehydratableTarget: Codable, Equatable {
    case viewCipher(cipherId: String)
    case editCipher(cipherId: String)
}

extension RehydratableTarget {
    /// The app route to navigate to when rehydrating based on the target.
    var appRoute: AppRoute {
        switch self {
        case let .viewCipher(cipherId):
            .tab(.vault(.viewItem(id: cipherId)))
        case let .editCipher(cipherId):
            .tab(.vault(.editItemFrom(id: cipherId)))
        }
    }
}
