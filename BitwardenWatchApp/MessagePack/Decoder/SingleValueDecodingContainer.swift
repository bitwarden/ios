import Foundation

#if os(Linux)
let NSEC_PER_SEC: UInt64 = 1_000_000_000
#endif

extension _MessagePackDecoder {
    final class SingleValueContainer {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        var data: Data
        var index: Data.Index
        var currentSpec: DataSpec?

        init(data: Data, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.data = data
            index = self.data.startIndex
        }

        func checkCanDecode<T>(_ type: T.Type, format: UInt8) throws {
            guard index <= data.endIndex else {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Unexpected end of data")
            }

            guard data[index] == format else {
                let context = DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Invalid format: \(format)"
                )
                throw DecodingError.typeMismatch(type, context)
            }
        }

        var nonMatchingFloatDecodingStrategy: MessagePackDecoder.NonMatchingFloatDecodingStrategy {
            userInfo[MessagePackDecoder.nonMatchingFloatDecodingStrategyKey] as? MessagePackDecoder
                .NonMatchingFloatDecodingStrategy ?? .strict
        }
    }
}

extension _MessagePackDecoder.SingleValueContainer: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        let format = try? readByte()
        return format == 0xC0
    }

    func decode(_: Bool.Type) throws -> Bool {
        let format = try readByte()
        switch format {
        case 0xC2: return false
        case 0xC3: return true
        default:
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid format: \(format)")
            throw DecodingError.typeMismatch(Bool.self, context)
        }
    }

    func decode(_: String.Type) throws -> String {
        let length: Int
        let format = try readByte()
        switch format {
        case 0xA0 ... 0xBF:
            length = Int(format - 0xA0)
        case 0xD9:
            length = try Int(read(UInt8.self))
        case 0xDA:
            length = try Int(read(UInt16.self))
        case 0xDB:
            length = try Int(read(UInt32.self))
        default:
            throw DecodingError.dataCorruptedError(
                in: self,
                debugDescription: "Invalid format for String length: \(format)"
            )
        }

        let data = try read(length)
        guard let string = String(data: data, encoding: .utf8) else {
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Couldn't decode string with UTF-8 encoding"
            )
            throw DecodingError.dataCorrupted(context)
        }

        return string
    }

    func decode(_: Double.Type) throws -> Double {
        let format = try readByte()
        switch format {
        case 0xCA:
            switch nonMatchingFloatDecodingStrategy {
            case .strict:
                break
            case .cast:
                let bitPattern = try read(UInt32.self)
                return Double(Float(bitPattern: bitPattern))
            }
        case 0xCB:
            let bitPattern = try read(UInt64.self)
            return Double(bitPattern: bitPattern)
        default:
            break
        }
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid format: \(format)")
        throw DecodingError.typeMismatch(Double.self, context)
    }

    func decode(_: Float.Type) throws -> Float {
        let format = try readByte()
        switch format {
        case 0xCA:
            let bitPattern = try read(UInt32.self)
            return Float(bitPattern: bitPattern)
        case 0xCB:
            switch nonMatchingFloatDecodingStrategy {
            case .strict:
                break
            case .cast:
                let bitPattern = try read(UInt64.self)
                return Float(Double(bitPattern: bitPattern))
            }
        default:
            break
        }
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid format: \(format)")
        throw DecodingError.typeMismatch(Float.self, context)
    }

    func decode<T>(_: T.Type) throws -> T where T: BinaryInteger & Decodable {
        let format = try readByte()
        var t: T?

        switch format {
        case 0x00 ... 0x7F:
            t = T(format)
        case 0xCC:
            t = try T(exactly: read(UInt8.self))
        case 0xCD:
            t = try T(exactly: read(UInt16.self))
        case 0xCE:
            t = try T(exactly: read(UInt32.self))
        case 0xCF:
            t = try T(exactly: read(UInt64.self))
        case 0xD0:
            t = try T(exactly: read(Int8.self))
        case 0xD1:
            t = try T(exactly: read(Int16.self))
        case 0xD2:
            t = try T(exactly: read(Int32.self))
        case 0xD3:
            t = try T(exactly: read(Int64.self))
        case 0xE0 ... 0xFF:
            t = T(exactly: Int8(bitPattern: format))
        default:
            t = nil
        }

        guard let value = t else {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid format: \(format)")
            throw DecodingError.typeMismatch(T.self, context)
        }

        return value
    }

    func decode(_: Date.Type) throws -> Date {
        let format = try readByte()

        var seconds: TimeInterval
        var nanoseconds: TimeInterval

        switch format {
        case 0xD6:
            _ = try read(Int8.self) // -1
            nanoseconds = 0
            seconds = try TimeInterval(read(UInt32.self))
        case 0xD7:
            _ = try read(Int8.self) // -1
            let bitPattern = try read(UInt64.self)
            nanoseconds = TimeInterval(UInt32(bitPattern >> 34))
            seconds = TimeInterval(UInt32(bitPattern & 0x03_FFFF_FFFF))
        case 0xC7:
            _ = try read(Int8.self) // 12
            _ = try read(Int8.self) // -1
            nanoseconds = try TimeInterval(read(UInt32.self))
            seconds = try TimeInterval(read(Int64.self))
        default:
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid format: \(format)")
            throw DecodingError.typeMismatch(Date.self, context)
        }

        let timeInterval = TimeInterval(seconds) + nanoseconds / Double(NSEC_PER_SEC)

        return Date(timeIntervalSince1970: timeInterval)
    }

    func decode(_: Data.Type) throws -> Data {
        let length: Int
        let format = try readByte()
        switch format {
        case 0xC4:
            length = try Int(read(UInt8.self))
        case 0xC5:
            length = try Int(read(UInt16.self))
        case 0xC6:
            length = try Int(read(UInt32.self))
        default:
            throw DecodingError.dataCorruptedError(
                in: self,
                debugDescription: "Invalid format for Data length: \(format)"
            )
        }

        return data.subdata(in: index ..< index.advanced(by: length))
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        switch type {
        case is Data.Type:
            return try decode(Data.self) as! T
        case is Date.Type:
            return try decode(Date.self) as! T
        default:
            let decoder = _MessagePackDecoder(data: data)
            let value = try T(from: decoder)
            if let nextIndex = decoder.container?.index {
                index = nextIndex
            }

            return value
        }
    }
}

extension _MessagePackDecoder.SingleValueContainer: MessagePackDecodingContainer {}
