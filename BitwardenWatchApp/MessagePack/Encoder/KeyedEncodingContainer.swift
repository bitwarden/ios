import Foundation

extension _MessagePackEncoder {
    final class KeyedContainer<Key> where Key: CodingKey {
        private var storage: [AnyCodingKey: _MessagePackEncodingContainer] = [:]

        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
            codingPath + [key]
        }

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
}

extension _MessagePackEncoder.KeyedContainer: KeyedEncodingContainerProtocol {
    func encodeNil(forKey key: Key) throws {
        var container = nestedSingleValueContainer(forKey: key)
        try container.encodeNil()
    }

    func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        var container = nestedSingleValueContainer(forKey: key)
        try container.encode(value)
    }

    private func nestedSingleValueContainer(forKey key: Key) -> SingleValueEncodingContainer {
        let container = _MessagePackEncoder.SingleValueContainer(
            codingPath: nestedCodingPath(forKey: key),
            userInfo: userInfo
        )
        storage[AnyCodingKey(key)] = container
        return container
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let container = _MessagePackEncoder.UnkeyedContainer(
            codingPath: nestedCodingPath(forKey: key),
            userInfo: userInfo
        )
        storage[AnyCodingKey(key)] = container

        return container
    }

    func nestedContainer<NestedKey>(
        keyedBy _: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let container = _MessagePackEncoder.KeyedContainer<NestedKey>(
            codingPath: nestedCodingPath(forKey: key),
            userInfo: userInfo
        )
        storage[AnyCodingKey(key)] = container

        return KeyedEncodingContainer(container)
    }

    func superEncoder() -> Encoder {
        fatalError("Unimplemented") // FIXME:
    }

    func superEncoder(forKey _: Key) -> Encoder {
        fatalError("Unimplemented") // FIXME:
    }
}

extension _MessagePackEncoder.KeyedContainer: _MessagePackEncodingContainer {
    var data: Data {
        var data = Data()

        let length = storage.count
        if let uint16 = UInt16(exactly: length) {
            if length <= 15 {
                data.append(0x80 + UInt8(length))
            } else {
                data.append(0xDE)
                data.append(contentsOf: uint16.bytes)
            }
        } else if let uint32 = UInt32(exactly: length) {
            data.append(0xDF)
            data.append(contentsOf: uint32.bytes)
        } else {
            fatalError()
        }

        for (key, container) in storage {
            let keyContainer = _MessagePackEncoder.SingleValueContainer(codingPath: codingPath, userInfo: userInfo)
            try! keyContainer.encode(key.stringValue)
            data.append(keyContainer.data)

            data.append(container.data)
        }

        return data
    }
}
