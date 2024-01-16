import Foundation

extension _MessagePackEncoder {
    final class SingleValueContainer {
        private var storage: Data = .init()

        fileprivate var canEncodeNewValue = true
        fileprivate func checkCanEncode(value: Any?) throws {
            guard canEncodeNewValue else {
                let context = EncodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Attempt to encode value through single value container when previously value already encoded."
                )
                throw EncodingError.invalidValue(value as Any, context)
            }
        }

        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
}

extension _MessagePackEncoder.SingleValueContainer: SingleValueEncodingContainer {
    func encodeNil() throws {
        try checkCanEncode(value: nil)
        defer { self.canEncodeNewValue = false }

        storage.append(0xC0)
    }

    func encode(_ value: Bool) throws {
        try checkCanEncode(value: nil)
        defer { self.canEncodeNewValue = false }

        switch value {
        case false:
            storage.append(0xC2)
        case true:
            storage.append(0xC3)
        }
    }

    func encode(_ value: String) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        guard let data = value.data(using: .utf8) else {
            let context = EncodingError.Context(
                codingPath: codingPath,
                debugDescription: "Cannot encode string using UTF-8 encoding."
            )
            throw EncodingError.invalidValue(value, context)
        }

        let length = data.count
        if let uint8 = UInt8(exactly: length) {
            if uint8 <= 31 {
                storage.append(0xA0 + uint8)
            } else {
                storage.append(0xD9)
                storage.append(contentsOf: uint8.bytes)
            }
        } else if let uint16 = UInt16(exactly: length) {
            storage.append(0xDA)
            storage.append(contentsOf: uint16.bytes)
        } else if let uint32 = UInt32(exactly: length) {
            storage.append(0xDB)
            storage.append(contentsOf: uint32.bytes)
        } else {
            let context = EncodingError.Context(
                codingPath: codingPath,
                debugDescription: "Cannot encode string with length \(length)."
            )
            throw EncodingError.invalidValue(value, context)
        }

        storage.append(data)
    }

    func encode(_ value: Double) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        storage.append(0xCB)
        storage.append(contentsOf: value.bitPattern.bytes)
    }

    func encode(_ value: Float) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        storage.append(0xCA)
        storage.append(contentsOf: value.bitPattern.bytes)
    }

    func encode<T>(_ value: T) throws where T: BinaryInteger & Encodable {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        if value < 0 {
            if let int8 = Int8(exactly: value) {
                return try encode(int8)
            } else if let int16 = Int16(exactly: value) {
                return try encode(int16)
            } else if let int32 = Int32(exactly: value) {
                return try encode(int32)
            } else if let int64 = Int64(exactly: value) {
                return try encode(int64)
            }
        } else {
            if let uint8 = UInt8(exactly: value) {
                return try encode(uint8)
            } else if let uint16 = UInt16(exactly: value) {
                return try encode(uint16)
            } else if let uint32 = UInt32(exactly: value) {
                return try encode(uint32)
            } else if let uint64 = UInt64(exactly: value) {
                return try encode(uint64)
            }
        }

        let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode integer \(value).")
        throw EncodingError.invalidValue(value, context)
    }

    func encode(_ value: Int8) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        if value >= 0, value <= 127 {
            storage.append(UInt8(value))
        } else if value < 0, value >= -31 {
            storage.append(0xE0 + (0x1F & UInt8(truncatingIfNeeded: value)))
        } else {
            storage.append(0xD0)
            storage.append(contentsOf: value.bytes)
        }
    }

    func encode(_ value: Int16) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        storage.append(0xD1)
        storage.append(contentsOf: value.bytes)
    }

    func encode(_ value: Int32) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        storage.append(0xD2)
        storage.append(contentsOf: value.bytes)
    }

    func encode(_ value: Int64) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        storage.append(0xD3)
        storage.append(contentsOf: value.bytes)
    }

    func encode(_ value: UInt8) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        if value <= 127 {
            storage.append(value)
        } else {
            storage.append(0xCC)
            storage.append(contentsOf: value.bytes)
        }
    }

    func encode(_ value: UInt16) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        storage.append(0xCD)
        storage.append(contentsOf: value.bytes)
    }

    func encode(_ value: UInt32) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        storage.append(0xCE)
        storage.append(contentsOf: value.bytes)
    }

    func encode(_ value: UInt64) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        storage.append(0xCF)
        storage.append(contentsOf: value.bytes)
    }

    func encode(_ value: Date) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        let timeInterval = value.timeIntervalSince1970
        let (integral, fractional) = modf(timeInterval)

        let seconds = Int64(integral)
        let nanoseconds = UInt32(fractional * Double(NSEC_PER_SEC))

        if seconds < 0 || seconds > UInt32.max {
            storage.append(0xC7)
            storage.append(0x0C)
            storage.append(0xFF)
            storage.append(contentsOf: nanoseconds.bytes)
            storage.append(contentsOf: seconds.bytes)
        } else if nanoseconds > 0 {
            storage.append(0xD7)
            storage.append(0xFF)
            storage.append(contentsOf: ((UInt64(nanoseconds) << 34) + UInt64(seconds)).bytes)
        } else {
            storage.append(0xD6)
            storage.append(0xFF)
            storage.append(contentsOf: UInt32(seconds).bytes)
        }
    }

    func encode(_ value: Data) throws {
        let length = value.count
        if let uint8 = UInt8(exactly: length) {
            storage.append(0xC4)
            storage.append(uint8)
            storage.append(value)
        } else if let uint16 = UInt16(exactly: length) {
            storage.append(0xC5)
            storage.append(contentsOf: uint16.bytes)
            storage.append(value)
        } else if let uint32 = UInt32(exactly: length) {
            storage.append(0xC6)
            storage.append(contentsOf: uint32.bytes)
            storage.append(value)
        } else {
            let context = EncodingError.Context(
                codingPath: codingPath,
                debugDescription: "Cannot encode data of length \(value.count)."
            )
            throw EncodingError.invalidValue(value, context)
        }
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        switch value {
        case let data as Data:
            try encode(data)
        case let date as Date:
            try encode(date)
        default:
            let encoder = _MessagePackEncoder()
            try value.encode(to: encoder)
            storage.append(encoder.data)
        }
    }
}

extension _MessagePackEncoder.SingleValueContainer: _MessagePackEncodingContainer {
    var data: Data {
        storage
    }
}
