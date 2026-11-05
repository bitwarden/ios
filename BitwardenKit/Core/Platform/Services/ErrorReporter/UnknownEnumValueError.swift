import Foundation

// MARK: - UnknownEnumValueError

/// An error reported when an API response contains an enum raw value that this version of the app
/// doesn't recognize, and the item containing it is dropped or rejected as a result.
///
/// The error domain includes the enum's name, so each enum is grouped as its own non-fatal issue
/// in Crashlytics, and the user info carries the unrecognized raw value and the identifier of the
/// affected item.
///
/// - Important: This error is intentionally loggable. Only the enum name, raw value, and item
///   identifier may be included. Never add names, URIs, notes, or any other vault content.
///
public struct UnknownEnumValueError: CustomNSError, Equatable {
    // MARK: Types

    /// The keys used in the error's user info.
    ///
    public enum UserInfoKey {
        /// The key for the identifier of the item containing the unrecognized value.
        public static let itemId = "ItemId"

        /// The key for the unrecognized raw value.
        public static let rawValue = "RawValue"
    }

    // MARK: Type Properties

    /// The base error domain. The domain of each error appends the enum name to this.
    public static var errorDomain: String {
        "Unknown Enum Value"
    }

    // MARK: Properties

    /// The name of the enum type that the raw value couldn't be mapped to.
    public let enumName: String

    /// The identifier of the item containing the unrecognized value, if known.
    public let itemId: String?

    /// The unrecognized raw value, as a string.
    public let rawValue: String

    // MARK: CustomNSError

    /// The error domain, which includes the enum name so that each enum is grouped separately in
    /// Crashlytics (e.g. `Unknown Enum Value: CipherType`).
    public var errorDomain: String {
        "\(Self.errorDomain): \(enumName)"
    }

    /// The domain used when bridging to `NSError`.
    ///
    /// `CustomNSError` only supports a static `errorDomain`, so bridging would otherwise use the
    /// same domain for every enum. Overriding the `Error` protocol's `_domain` requirement makes
    /// `(error as NSError).domain`, which Crashlytics groups by, include the enum name.
    public var _domain: String { // swiftlint:disable:this identifier_name
        errorDomain
    }

    public var errorCode: Int {
        BitwardenError.Code.unknownEnumValue.rawValue
    }

    public var errorUserInfo: [String: Any] {
        var userInfo: [String: Any] = [UserInfoKey.rawValue: rawValue]
        if let itemId {
            userInfo[UserInfoKey.itemId] = itemId
        }
        return userInfo
    }

    // MARK: Initialization

    /// Initialize an `UnknownEnumValueError`.
    ///
    /// - Parameters:
    ///   - enumName: The name of the enum type that the raw value couldn't be mapped to.
    ///   - rawValue: The unrecognized raw value, as a string.
    ///   - itemId: The identifier of the item containing the unrecognized value, if known.
    ///
    public init(enumName: String, rawValue: String, itemId: String? = nil) {
        self.enumName = enumName
        self.itemId = itemId
        self.rawValue = rawValue
    }

    /// Initialize an `UnknownEnumValueError` for an unrecognized raw value of an enum type, using
    /// the type's name as the enum name.
    ///
    /// - Parameters:
    ///   - type: The enum type that the raw value couldn't be mapped to.
    ///   - rawValue: The unrecognized raw value.
    ///   - itemId: The identifier of the item containing the unrecognized value, if known.
    ///
    public init<T: RawRepresentable>(_ type: T.Type, rawValue: T.RawValue, itemId: String? = nil) {
        self.init(
            enumName: String(describing: type),
            rawValue: String(describing: rawValue),
            itemId: itemId,
        )
    }

    /// Initialize an `UnknownEnumValueError` from an `OpenEnum` value, if it holds an unrecognized
    /// raw value.
    ///
    /// - Parameters:
    ///   - value: The decoded value.
    ///   - itemId: The identifier of the item containing the value, if known.
    /// - Returns: `nil` if the value is missing or is a known value.
    ///
    public init?<T>(_ value: OpenEnum<T>?, itemId: String? = nil) {
        guard case let .unknown(rawValue) = value else { return nil }
        self.init(T.self, rawValue: rawValue, itemId: itemId)
    }
}
