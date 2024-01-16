import Foundation

extension _MessagePackDecoder {
    final class KeyedContainer<Key> where Key: CodingKey {
        lazy var nestedContainers: [String: MessagePackDecodingContainer] = {
            guard let count = self.count else {
                return [:]
            }

            var nestedContainers: [String: MessagePackDecodingContainer] = [:]

            let unkeyedContainer = UnkeyedContainer(
                data: self.data.suffix(from: self.index),
                codingPath: self.codingPath,
                userInfo: self.userInfo
            )
            if currentSpec != nil, currentSpec!.isObj {
                unkeyedContainer.count = count
            } else {
                unkeyedContainer.count = count * 2
            }

            do {
                var iterator = unkeyedContainer.nestedContainers.makeIterator()

                for _ in 0 ..< count {
                    var key = ""
                    if currentSpec == nil || !currentSpec!.isObj {
                        guard let keyContainer = iterator.next() as? _MessagePackDecoder.SingleValueContainer else {
                            fatalError() // FIXME:
                        }

                        key = try keyContainer.decode(String.self)
                    }

                    guard let container = iterator.next() else {
                        fatalError() // FIXME:
                    }

                    if currentSpec != nil, currentSpec!.isObj {
                        key = container.currentSpec!.name
                    }

                    container.codingPath += [AnyCodingKey(stringValue: key)!]
                    nestedContainers[key] = container
                }
            } catch {
                fatalError("\(error)") // FIXME:
            }

            self.index = unkeyedContainer.index

            return nestedContainers
        }()

        lazy var count: Int? = {
            do {
                let format = try self.readByte()

                if currentSpec != nil, currentSpec!.isObj, 0x90 ... 0x9F ~= format {
                    return Int(format & 0x0F)
                }

                switch format {
                case 0x80 ... 0x8F:
                    return Int(format & 0x0F)
                case 0xDE:
                    return try Int(read(UInt16.self))
                case 0xDF:
                    return try Int(read(UInt32.self))
                default:
                    return nil
                }
            } catch {
                return nil
            }
        }()

        var data: Data
        var index: Data.Index
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        var currentSpec: DataSpec?

        func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
            codingPath + [key]
        }

        init(data: Data, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.data = data
            index = self.data.startIndex
        }

        func checkCanDecodeValue(forKey key: Key) throws {
            guard contains(key) else {
                let context = DecodingError.Context(codingPath: codingPath, debugDescription: "key not found: \(key)")
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
}

extension _MessagePackDecoder.KeyedContainer: KeyedDecodingContainerProtocol {
    var allKeys: [Key] {
        nestedContainers.keys.map { Key(stringValue: $0)! }
    }

    func contains(_ key: Key) -> Bool {
        nestedContainers.keys.contains(key.stringValue)
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        try checkCanDecodeValue(forKey: key)

        let nestedContainer = nestedContainers[key.stringValue]

        switch nestedContainer {
        case is _MessagePackDecoder.KeyedContainer<AnyCodingKey>,
             is _MessagePackDecoder.UnkeyedContainer:
            return false
        case let singleValueContainer as _MessagePackDecoder.SingleValueContainer:
            return singleValueContainer.decodeNil()
        default:
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "cannot decode nil for key: \(key)"
            )
            throw DecodingError.typeMismatch(Any?.self, context)
        }
    }

    func decode<T>(_: T.Type, forKey key: Key) throws -> T where T: Decodable {
        try checkCanDecodeValue(forKey: key)

        let container = nestedContainers[key.stringValue]!
        let decoder = MessagePackDecoder()

        if userInfo.keys.contains(MessagePackDecoder.dataSpecKey) {
            decoder.userInfo[MessagePackDecoder.dataSpecKey] = container.currentSpec!.dataSpecBuilder?
                .copy() as? DataSpecBuilder
            if container.currentSpec!.isArray {
                decoder.userInfo[MessagePackDecoder.isArrayDataSpecKey] = true
            }
        }

        let value = try decoder.decode(T.self, from: container.data)

        return value
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        try checkCanDecodeValue(forKey: key)

        guard let unkeyedContainer = nestedContainers[key.stringValue] as? _MessagePackDecoder.UnkeyedContainer else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "cannot decode nested container for key: \(key)"
            )
        }

        return unkeyedContainer
    }

    func nestedContainer<NestedKey>(
        keyedBy _: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        try checkCanDecodeValue(forKey: key)

        guard let keyedContainer = nestedContainers[key.stringValue] as? _MessagePackDecoder.KeyedContainer<NestedKey>
        else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "cannot decode nested container for key: \(key)"
            )
        }

        return KeyedDecodingContainer(keyedContainer)
    }

    func superDecoder() throws -> Decoder {
        _MessagePackDecoder(data: data)
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        let decoder = _MessagePackDecoder(data: data)
        decoder.codingPath = [key]

        return decoder
    }
}

extension _MessagePackDecoder.KeyedContainer: MessagePackDecodingContainer {}
