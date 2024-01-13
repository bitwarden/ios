import Foundation

/// An object that encodes instances of a data type as MessagePack objects.
public final class MessagePackEncoder {
    public init() {}

    /// A dictionary you use to customize the encoding process
    /// by providing contextual information.
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    /// Returns a MessagePack-encoded representation of the value you supply.
    ///
    /// - Parameters:
    ///    - value: The value to encode as MessagePack.
    /// - Throws: `EncodingError.invalidValue(_:_:)`
    ///            if the value can't be encoded as a MessagePack object.
    public func encode<T>(_ value: T) throws -> Data where T: Encodable {
        let encoder = _MessagePackEncoder()
        encoder.userInfo = userInfo

        switch value {
        case let data as Data:
            try Box<Data>(data).encode(to: encoder)
        case let date as Date:
            try Box<Date>(date).encode(to: encoder)
        default:
            try value.encode(to: encoder)
        }

        return encoder.data
    }
}

// MARK: - TopLevelEncoder

#if canImport(Combine)
import Combine

extension MessagePackEncoder: TopLevelEncoder {
    public typealias Input = Data
}
#endif

// MARK: -

protocol _MessagePackEncodingContainer {
    var data: Data { get }
}

class _MessagePackEncoder {
    var codingPath: [CodingKey] = []

    var userInfo: [CodingUserInfoKey: Any] = [:]

    fileprivate var container: _MessagePackEncodingContainer?

    var data: Data {
        container?.data ?? Data()
    }
}

extension _MessagePackEncoder: Encoder {
    fileprivate func assertCanCreateContainer() {
        precondition(container == nil)
    }

    func container<Key>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        assertCanCreateContainer()

        let container = KeyedContainer<Key>(codingPath: codingPath, userInfo: userInfo)
        self.container = container

        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        assertCanCreateContainer()

        let container = UnkeyedContainer(codingPath: codingPath, userInfo: userInfo)
        self.container = container

        return container
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        assertCanCreateContainer()

        let container = SingleValueContainer(codingPath: codingPath, userInfo: userInfo)
        self.container = container

        return container
    }
}
