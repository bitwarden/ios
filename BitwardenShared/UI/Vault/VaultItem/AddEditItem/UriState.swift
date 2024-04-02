import BitwardenSdk
import Foundation

// MARK: UriState

/// An object that represents a URI that the user can enter or edit for a login item.
///
struct UriState: Equatable, Hashable, Identifiable {
    // MARK: Properties

    /// A unique identifier for this uri.
    var id: String

    /// The uri match type for this uri.
    var matchType: DefaultableType<UriMatchType>

    /// The string representation of this uri.
    var uri: String

    /// The URI's checksum.
    let uriChecksum: String?

    /// Creates a `LoginUriView` from this object.
    ///
    /// If `uri` is empty, this property returns `nil`.
    var loginUriView: LoginUriView? {
        guard !uri.isEmpty else { return nil }

        let uriMatchType: BitwardenSdk.UriMatchType? = switch matchType {
        case .default: nil
        case let .custom(type): BitwardenSdk.UriMatchType(type: type)
        }

        return LoginUriView(
            uri: uri,
            match: uriMatchType,
            uriChecksum: uriChecksum
        )
    }

    /// Creates a new `UriState`.
    ///
    /// - Parameters:
    ///   - id: The id for this uri.
    ///   - matchType: The match type for this uri.
    ///   - uri: The string representation for this uri.
    ///   - uriChecksum: The URI's checksum.
    ///
    init(
        id: String = UUID().uuidString,
        matchType: DefaultableType<UriMatchType> = .default,
        uri: String = "",
        uriChecksum: String? = nil
    ) {
        self.id = id
        self.matchType = matchType
        self.uri = uri
        self.uriChecksum = uriChecksum
    }

    /// Initialize a `UriState` from a `LoginUriView`.
    ///
    /// - Parameter loginUriView: The `LoginUriView` used to initialize the `UriState`.
    ///
    init(loginUriView: LoginUriView) {
        let matchType: DefaultableType<UriMatchType> = if let matchType = loginUriView.match {
            .custom(UriMatchType(match: matchType))
        } else {
            .default
        }

        self.init(
            matchType: matchType,
            uri: loginUriView.uri ?? "",
            uriChecksum: loginUriView.uriChecksum
        )
    }
}
