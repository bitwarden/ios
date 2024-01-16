import Foundation

extension _MessagePackDecoder {
    final class UnkeyedContainer {
        var codingPath: [CodingKey]

        var nestedCodingPath: [CodingKey] {
            codingPath + [AnyCodingKey(intValue: count ?? 0)!]
        }

        var userInfo: [CodingUserInfoKey: Any]

        var data: Data
        var index: Data.Index
        var currentSpec: DataSpec?

        lazy var count: Int? = {
            do {
                let format = try self.readByte()
                switch format {
                case 0x90 ... 0x9F:
                    return Int(format & 0x0F)
                case 0xDC:
                    return try Int(read(UInt16.self))
                case 0xDD:
                    return try Int(read(UInt32.self))
                default:
                    return nil
                }
            } catch {
                return nil
            }
        }()

        var currentIndex: Int = 0

        lazy var nestedContainers: [MessagePackDecodingContainer] = {
            guard let count = self.count else {
                return []
            }

            var nestedContainers: [MessagePackDecodingContainer] = []

            do {
                for _ in 0 ..< count {
                    let container = try self.decodeContainer()
                    nestedContainers.append(container)
                }
            } catch {
                fatalError("\(error)") // FIXME:
            }

            self.currentIndex = 0

            return nestedContainers
        }()

        init(data: Data, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.data = data
            index = self.data.startIndex
        }

        var isAtEnd: Bool {
            guard let count else {
                return true
            }

            return currentIndex >= count
        }

        func checkCanDecodeValue() throws {
            guard !isAtEnd else {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Unexpected end of data")
            }
        }
    }
}

extension _MessagePackDecoder.UnkeyedContainer: UnkeyedDecodingContainer {
    func decodeNil() throws -> Bool {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let nestedContainer = nestedContainers[currentIndex]

        switch nestedContainer {
        case is _MessagePackDecoder.KeyedContainer<AnyCodingKey>,
             is _MessagePackDecoder.UnkeyedContainer:
            return false
        case let singleValueContainer as _MessagePackDecoder.SingleValueContainer:
            return singleValueContainer.decodeNil()
        default:
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "cannot decode nil for index: \(currentIndex)"
            )
            throw DecodingError.typeMismatch(Any?.self, context)
        }
    }

    func decode<T>(_: T.Type) throws -> T where T: Decodable {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        if userInfo.keys.contains(MessagePackDecoder.isArrayDataSpecKey) {
            currentSpec = DataSpec(
                "",
                false,
                true,
                (userInfo[MessagePackDecoder.dataSpecKey] as? DataSpecBuilder)?.copy() as? DataSpecBuilder
            )
        }

        let container = nestedContainers[currentIndex]
        let decoder = MessagePackDecoder()

        if userInfo.keys.contains(MessagePackDecoder.dataSpecKey) {
            decoder
                .userInfo[MessagePackDecoder.dataSpecKey] =
                (userInfo[MessagePackDecoder.dataSpecKey] as? DataSpecBuilder)?.copy() as? DataSpecBuilder
        }

        let value = try decoder.decode(T.self, from: container.data)

        return value
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let container = nestedContainers[currentIndex] as! _MessagePackDecoder.UnkeyedContainer

        return container
    }

    func nestedContainer<NestedKey>(
        keyedBy _: NestedKey.Type
    ) throws -> KeyedDecodingContainer<NestedKey>where NestedKey: CodingKey {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let container = nestedContainers[currentIndex] as! _MessagePackDecoder.KeyedContainer<NestedKey>

        return KeyedDecodingContainer(container)
    }

    func superDecoder() throws -> Decoder {
        _MessagePackDecoder(data: data)
    }
}

extension _MessagePackDecoder.UnkeyedContainer {
    func decodeContainer() throws -> MessagePackDecodingContainer {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let startIndex = index

        var currDataSpec: DataSpec? = nil
        if currentSpec != nil, currentSpec!.isArray, currentSpec!.dataSpecBuilder != nil {
            currDataSpec = DataSpec("", true, false, currentSpec!.dataSpecBuilder!.copy() as? DataSpecBuilder)
        } else {
            let dataSpec = userInfo[MessagePackDecoder.dataSpecKey] as? DataSpecBuilder
            if let currDS = dataSpec?.next() {
                currDataSpec = DataSpec(
                    currDS.name,
                    currDS.isObj,
                    currDS.isArray,
                    currDS.dataSpecBuilder?.copy() as? DataSpecBuilder
                )
            }
        }

        let length: Int
        let format = try readByte()
        switch format {
        case 0x00 ... 0x7F,
             0xC0, 0xC2, 0xC3,
             0xE0 ... 0xFF:
            length = 0
        case 0xCC, 0xD0, 0xD4:
            length = 1
        case 0xCD, 0xD1, 0xD5:
            length = 2
        case 0xCA, 0xCE, 0xD2:
            length = 4
        case 0xCB, 0xCF, 0xD3:
            length = 8
        case 0xD6:
            length = 5
        case 0xD7:
            length = 9
        case 0xD8:
            length = 16
        case 0xA0 ... 0xBF:
            length = Int(format - 0xA0)
        case 0xC4, 0xC7, 0xD9:
            length = try Int(read(UInt8.self))
        case 0xC5, 0xC8, 0xDA:
            length = try Int(read(UInt16.self))
        case 0xC6, 0xC9, 0xDB:
            length = try Int(read(UInt32.self))
        case 0x80 ... 0x8F, 0xDE, 0xDF:
            let container = _MessagePackDecoder.KeyedContainer<AnyCodingKey>(
                data: data.suffix(from: startIndex),
                codingPath: nestedCodingPath,
                userInfo: userInfo
            )
            container.currentSpec = currDataSpec
            _ = container.nestedContainers // FIXME:
            index = container.index

            return container
        case 0x90 ... 0x9F, 0xDC, 0xDD:
            if currDataSpec != nil, currDataSpec!.isObj {
                var objUserInfo = userInfo
                objUserInfo[MessagePackDecoder.dataSpecKey] = currDataSpec!.dataSpecBuilder!

                let container = _MessagePackDecoder.KeyedContainer<AnyCodingKey>(
                    data: data.suffix(from: startIndex),
                    codingPath: nestedCodingPath,
                    userInfo: objUserInfo
                )
                container.currentSpec = currDataSpec
                _ = container.nestedContainers // FIXME:
                index = container.index

                return container
            }

            var arrUserInfo = userInfo
            if currDataSpec != nil, currDataSpec!.isArray {
                arrUserInfo[MessagePackDecoder.dataSpecKey] = currDataSpec!.dataSpecBuilder!
            }

            let container = _MessagePackDecoder.UnkeyedContainer(
                data: data.suffix(from: startIndex),
                codingPath: nestedCodingPath,
                userInfo: arrUserInfo
            )
            container.currentSpec = currDataSpec
            _ = container.nestedContainers // FIXME:

            index = container.index

            return container
        default:
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Invalid format: \(format)")
        }

        let range: Range<Data.Index> = startIndex ..< index.advanced(by: length)
        index = range.upperBound

        let container = _MessagePackDecoder.SingleValueContainer(
            data: data.subdata(in: range),
            codingPath: codingPath,
            userInfo: userInfo
        )
        container.currentSpec = currDataSpec

        return container
    }
}

extension _MessagePackDecoder.UnkeyedContainer: MessagePackDecodingContainer {}
