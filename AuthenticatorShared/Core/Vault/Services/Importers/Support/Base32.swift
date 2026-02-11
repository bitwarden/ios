import Foundation

public enum Base32Error: Error {
    case invalidBase32String
    case invalidBase32PaddedStringLength
}

/// Helpful functions for working with base32 encoding.
///
/// Adapted from https://github.com/markrenaud/Base32Encoder/blob/master/Base32Encoder/Base32.swift
enum Base32 {
    struct Octets {
        let octet1Index: Int
        let octet2Index: Int?
        let bitOffset: Int
    }

    private static let encodingTable = [
        "A", "B", "C", "D", "E", "F", "G", "H",
        "I", "J", "K", "L", "M", "N", "O", "P",
        "Q", "R", "S", "T", "U", "V", "W", "X",
        "Y", "Z", "2", "3", "4", "5", "6", "7",
    ]

    private static let decodingTable: [Character: String] = [
        "A": "00000", "B": "00001", "C": "00010", "D": "00011", "E": "00100", "F": "00101", "G": "00110", "H": "00111",
        "I": "01000", "J": "01001", "K": "01010", "L": "01011", "M": "01100", "N": "01101", "O": "01110", "P": "01111",
        "Q": "10000", "R": "10001", "S": "10010", "T": "10011", "U": "10100", "V": "10101", "W": "10110", "X": "10111",
        "Y": "11000", "Z": "11001", "2": "11010", "3": "11011", "4": "11100", "5": "11101", "6": "11110", "7": "11111",
    ]

    /// Returns the index(es) and offsets of the quintet of bits from
    /// an array of octets (Bytes) aka `[UInt8]`
    /// - Note:                    if the quintet of bits is fully
    ///                            contained within an octet, the
    ///                            `octet2Index` will be nil
    /// - Parameter quintetIndex:  the index (0-based) quintet-bit
    ///                            sequence to map against the indexes
    ///                            (0-based) of octet-bit sequences
    /// - Returns:                 mapped octet-bit indexes of the `UInt8`s
    ///                            involved and the offset of the quintet-bits
    ///                            in the first octet
    /// - Important:               For better understanding - see block below
    /// ````
    /// +---------+----------+---------+
    /// |01234 567|01 23456 7|0123 4567|   Octets Offset
    /// +---------+----------+---------+
    /// |01110 110|11 00000 1|1111 1010|   Octet Data Bits
    /// +---------+----------+---------+
    /// |< 1 > < 2| > < 3 > <|.4 > < 5.|>  Quintets
    /// +---------+----------+---------+-+
    /// |01110|110 11|00000|1 1111|1010  | Quintent Data Bits
    /// +-----+------+-----+------+------+
    ///                            <====> 5th character
    ///                     <====> 4th character
    ///              <===> 3rd character
    ///        <====> 2nd character
    ///  <===> 1st character
    ///
    ///
    /// Thus, for 3 octets (bytes) of data we will have 5 quintets
    /// ````
    ///
    static func octetsForQuintet(_ quintetIndex: Int) -> Octets {
        let octetIndex = (quintetIndex * 5) / 8
        let octetBitOffset = (quintetIndex * 5) % 8
        let overhangsOctet = octetBitOffset > 3

        return Octets(
            octet1Index: octetIndex,
            octet2Index: overhangsOctet ? octetIndex + 1 : nil,
            bitOffset: octetBitOffset,
        )
    }

    /// Joins two bytes together to form a 16-bit UInt
    /// - Parameter leadingByte:   an octet of bits (`UInt8`) that will
    ///                            represent the leading 8-bits of resultant
    ///                            `UInt16`
    /// - Parameter trailingByte:  an octet of bits (`UInt8`) that will
    ///                            represent the trailing 8-bits of resultant
    ///                            `UInt16`
    /// - Returns:                 the combined 8-bit bytes as a 16-bit `UInt16`
    /// - Note:                    example combination
    /// ````
    /// leadingByte     = 0b00000001            // 1
    /// trailingByte    =         0b10000001    // 129
    /// result          = 0b0000000110000001    // 385
    /// ````
    ///
    static func combineUInt8(leadingByte: UInt8, trailingByte: UInt8) -> UInt16 {
        // convert the leadingByte to UInt16 and bitshift it 8 positions
        // using the example from function documentation:
        // UInt8: 00000001 convert to UInt16: 00000000 00000001
        // bitshift UInt16 by 8: (- 00000000) 00000001 (+ 00000000) = 00000001 00000000
        let a16bit = UInt16(leadingByte) << 8 // eg. 00000001 00000000
        // convert the trailingByte to 16 bit
        // using the example from function documentation:
        // UInt8: 10000001 convert to UInt16: 00000000 10000001
        let b16bit = UInt16(trailingByte) // 00000000 10000001
        // bitwise OR sextetPartA and sextetPartB
        // to give final combined UInt16
        let combined = a16bit | b16bit // 00000001 10000001
        return combined
    }

    /// Retrieves a number of bits from a given `UInt16` and returns the
    /// representation of those bits as `UInt16`.  See the note for a worked
    /// example.
    /// - Parameter numberOfBits:  the number of bits to retrieve
    /// - Parameter from:          the 16-bit `UInt16` from which to retrieve
    ///                            the bits
    /// - Parameter offset:        the offset of the bits to retrieve from
    ///                            the leading bit
    /// - Returns:                 the desired bits placed as trailing bits
    ///                            within a 16-bit integer
    /// - Note:                    example of retrieving 5 bits offset from
    ///                            the leading bit by 3
    /// ````
    /// 16-bit     = 0111010011110100         = 0b0111010011110100 -> 29940
    /// desired    = ---10100--------         = 0b10100            -> 20
    ///
    /// we can achieve this by bitshifting left by the offset (3)
    /// then bitshifting right by (16 - numberOfBits(5)) = (11)
    /// and then the trailing 5-bits will be our desired bits
    ///
    /// 0111010011110100 << 3  = (-011) 1010011110100 (+ 000)
    /// = 1010011110100000
    /// 1010011110100000 >> 11 = (+00000000000) 10100 (- 11110100000)
    /// 0000000000010100       = 20 (desired result)
    /// ````
    ///
    static func getBitValue(numberOfBits: UInt16, from originalBits: UInt16, offset: UInt16) -> UInt16 {
        (originalBits << offset) >> (16 - numberOfBits)
    }

    /// Converts a data array to an array of 5-bit values held in a `UInt8` array.
    /// - Note: max value of any number in the resultant array will be
    ///         `0b00011111` = `31` as we will be only using the 5-bits
    ///         of the `UInt8`.  If there are not enough bits in the `UInt8`
    ///         array to fill up the last 5-bit value, it should be padded
    ///         with trailing `0`s (see example below)
    /// ````
    /// Example 8-bit byte data:
    /// [01110100] [11110111]
    ///
    /// Broken into 5-bits
    /// |01110 100|11 11011 1|
    /// |01110|100 11|11011|1 0000|
    ///                       ^^^^ padding 0s
    /// Which will be stored as trailing bits in `UInt8` array
    /// [00001110] [00010011]  [00011011]  [00010000]
    /// = 14       = 19        = 27        = 16
    ///
    /// ````
    ///
    static func dataTo5BitValueArray(data: Data) -> [UInt8] {
        let totalBits = data.count * 8
        let totalQuintets = Int(ceil(Double(totalBits) / 5.0))

        var quintets: [UInt8] = []
        var representation: [String] = []
        for quintetIndex in 0 ..< totalQuintets {
            let mapping = octetsForQuintet(quintetIndex)

            let leadingByte: UInt8 = data[mapping.octet1Index]
            var trailingByte: UInt8 = 0

            // if spans quintets
            if let octet2Index = mapping.octet2Index {
                if octet2Index < data.count {
                    trailingByte = data[octet2Index]
                } else {
                    trailingByte = 0
                }
            }
            let twoBytes = combineUInt8(leadingByte: leadingByte, trailingByte: trailingByte)

            let requiredBits = getBitValue(numberOfBits: 5, from: twoBytes, offset: UInt16(mapping.bitOffset))
            quintets.append(UInt8(requiredBits))
            representation.append(encodingTable[Int(requiredBits)])
        }

        return quintets
    }

    /// Converts bytes of data into a Base32 encoded string based on RFC3548
    /// - parameter data:      the `Data` to encode
    /// - parameter padding:   a boolean representing whether the padding character
    ///                        (`=`) should be appended to bring the number of
    ///                        characters in the string to a multiple of 8 (`false`
    ///                        by default)
    /// - returns:             `String` containing the Base32 encoded data
    ///
    static func encode(data: Data, padding: Bool = false) -> String {
        let mapped = dataTo5BitValueArray(data: data).map { inputBits -> String in
            encodingTable[Int(inputBits)]
        }

        var encodedString = mapped.joined()
        if padding {
            let modulo = mapped.count % 8
            if modulo > 0 {
                let padding = String(repeating: "=", count: 8 - modulo)
                encodedString += padding
            }
        }

        return encodedString
    }

    /// Converts Base32 string (RFC3548) into bytes of data
    /// - parameter string:    the Base32 string to decode
    /// - parameter padded:    a boolean representing whether the Base32 string is padded:
    ///                        ie. (`=`) is appended to bring the number of characters in
    ///                        the string to a multiple of 8. (`false`by default)
    /// - returns:             `Data` containing the Base32 encoded data
    /// - throws:              if the string is not a valid base32 string (or correct size if padded)
    ///
    static func decode(string encodedString: String, padded: Bool = false) throws -> Data {
        // Verify string size is a multiple of 8 if we expect padding
        if padded {
            guard encodedString.count % 8 == 0 else {
                throw Base32Error.invalidBase32PaddedStringLength
            }
        }

        // Verify string only contains valid Base32 characters (allow `=` as a valid character
        // if a padded string
        var validCharacters = CharacterSet(charactersIn: Base32.encodingTable.joined())
        if padded {
            validCharacters.insert("=")
        }
        let stringCharacters = CharacterSet(charactersIn: encodedString)

        guard stringCharacters.isSubset(of: validCharacters) else {
            throw Base32Error.invalidBase32String
        }

        var strippedEncodedString = encodedString
        if padded {
            // remove trailing `=`
            if let leadingCharacters = strippedEncodedString
                .split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)
                .first {
                strippedEncodedString = String(leadingCharacters)
            }
        }

        // create a long binary string from the decoded character quintets
        // we can use ! here as we are guaranteed to only have characters in the decoding table
        // by character set guarding above
        let binaryString = strippedEncodedString.map { decodingTable[$0]! }.joined()

        // break into binary octets - note the last octet may be less than 8 characters
        // we can discard it - as it is additional '0's not required
        var octetStrings = stride(from: 0, to: binaryString.count, by: 8).map { startPosition -> String in
            let startIndex = binaryString.index(binaryString.startIndex, offsetBy: startPosition)
            let endPosition = min(startPosition + 8, binaryString.count)
            let endIndex = binaryString.index(binaryString.startIndex, offsetBy: endPosition)
            let octetString = String(binaryString[startIndex ..< endIndex])
            return octetString
        }

        // discard any non-complete octet
        if let lastOctet = octetStrings.last {
            if lastOctet.count < 8 {
                _ = octetStrings.popLast()
            }
        }

        // convert octet strings to bytes
        let bytes = octetStrings.map { octetString -> UInt8 in
            UInt8(octetString, radix: 2) ?? 0
        }

        return Data(bytes)
    }
}

extension Data {
    /// Returns Base32 encoded string representation of the data (based on
    /// RFC3548)
    /// - parameter padded:    a boolean representing whether the padding
    ///                        character (`=`) should be appended to bring the total
    ///                        number of characters in the string to a multiple of 8
    ///                        (`false` by default)
    ///
    func base32String(padded: Bool = false) -> String {
        Base32.encode(data: self, padding: padded)
    }
}

extension String {
    /// Decodes a Base32 `String` into `Data` (based on RFC3548)
    /// - parameter padded:    a boolean representing whether the Base32 string is padded:
    /// ie. (`=`) is appended to bring the number of characters in
    /// the string to a multiple of 8. (`false`by default)
    /// - throws:              if the string is not a valid base32 string (or correct size if padded)
    ///
    func decodeBase32(padded: Bool = false) throws -> Data {
        try Base32.decode(string: self, padded: padded)
    }
}
