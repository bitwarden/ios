import Foundation

extension _MessagePackEncoder {
    final class UnkeyedContainer {
        private var storage: [_MessagePackEncodingContainer] = []

        var count: Int {
            storage.count
        }

        var codingPath: [CodingKey]

        var nestedCodingPath: [CodingKey] {
            codingPath + [AnyCodingKey(intValue: count)!]
        }

        var userInfo: [CodingUserInfoKey: Any]

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
}

extension _MessagePackEncoder.UnkeyedContainer: UnkeyedEncodingContainer {
    func encodeNil() throws {
        var container = nestedSingleValueContainer()
        try container.encodeNil()
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        var container = nestedSingleValueContainer()
        try container.encode(value)
    }

    private func nestedSingleValueContainer() -> SingleValueEncodingContainer {
        let container = _MessagePackEncoder.SingleValueContainer(codingPath: nestedCodingPath, userInfo: userInfo)
        storage.append(container)

        return container
    }

    func nestedContainer<NestedKey>(
        keyedBy _: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey>where NestedKey: CodingKey {
        let container = _MessagePackEncoder.KeyedContainer<NestedKey>(codingPath: nestedCodingPath, userInfo: userInfo)
        storage.append(container)

        return KeyedEncodingContainer(container)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let container = _MessagePackEncoder.UnkeyedContainer(codingPath: nestedCodingPath, userInfo: userInfo)
        storage.append(container)

        return container
    }

    func superEncoder() -> Encoder {
        fatalError("Unimplemented") // FIXME:
    }
}

extension _MessagePackEncoder.UnkeyedContainer: _MessagePackEncodingContainer {
    var data: Data {
        var data = Data()

        let length = storage.count
        if let uint16 = UInt16(exactly: length) {
            if uint16 <= 15 {
                data.append(UInt8(0x90 + uint16))
            } else {
                data.append(0xDC)
                data.append(contentsOf: uint16.bytes)
            }
        } else if let uint32 = UInt32(exactly: length) {
            data.append(0xDD)
            data.append(contentsOf: uint32.bytes)
        } else {
            fatalError()
        }

        for container in storage {
            data.append(container.data)
        }

        return data
    }
}
