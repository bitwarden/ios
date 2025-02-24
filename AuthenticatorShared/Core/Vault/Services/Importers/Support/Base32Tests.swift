import XCTest

@testable import AuthenticatorShared

/// Adapted from https://github.com/markrenaud/Base32Encoder/blob/master/Base32EncoderTests/Base32EncoderTests.swift
class Base32Tests: XCTestCase {
    // MARK: Encode Tests

    func test_encode_hello() {
        let data = "hello".data(using: .ascii)!

        XCTAssertEqual(Base32.encode(data: data, padding: false), "NBSWY3DP")
        XCTAssertEqual(Base32.encode(data: data, padding: true), "NBSWY3DP")
    }

    func test_encode_z() {
        let data = "Z".data(using: .ascii)!

        XCTAssertEqual(Base32.encode(data: data, padding: false), "LI")
        XCTAssertEqual(Base32.encode(data: data, padding: true), "LI======")
    }

    func test_encode_longstring() {
        let data = "what the! GET OUT OF HERE & +".data(using: .ascii)!

        XCTAssertEqual(Base32.encode(data: data, padding: false), "O5UGC5BAORUGKIJAI5CVIICPKVKCAT2GEBEEKUSFEATCAKY")
        XCTAssertEqual(Base32.encode(data: data, padding: true), "O5UGC5BAORUGKIJAI5CVIICPKVKCAT2GEBEEKUSFEATCAKY=")
    }

    func test_encode_RFC4648Examples() {
        var data = "".data(using: .ascii)!
        XCTAssertEqual(Base32.encode(data: data, padding: true), "")

        data = "f".data(using: .ascii)!
        XCTAssertEqual(Base32.encode(data: data, padding: true), "MY======")

        data = "fo".data(using: .ascii)!
        XCTAssertEqual(Base32.encode(data: data, padding: true), "MZXQ====")

        data = "foo".data(using: .ascii)!
        XCTAssertEqual(Base32.encode(data: data, padding: true), "MZXW6===")

        data = "foob".data(using: .ascii)!
        XCTAssertEqual(Base32.encode(data: data, padding: true), "MZXW6YQ=")

        data = "fooba".data(using: .ascii)!
        XCTAssertEqual(Base32.encode(data: data, padding: true), "MZXW6YTB")

        data = "foobar".data(using: .ascii)!
        XCTAssertEqual(Base32.encode(data: data, padding: true), "MZXW6YTBOI======")
    }

    // MARK: Decode Tests

    func test_decode_throwsOnInvalidString() {
        var invalidString = "123BDG$"
        XCTAssertThrowsError(try Base32.decode(string: invalidString))

        invalidString = "123bBDG"
        XCTAssertThrowsError(try Base32.decode(string: invalidString))

        invalidString = "8"
        XCTAssertThrowsError(try Base32.decode(string: invalidString))

        invalidString = "1"
        XCTAssertThrowsError(try Base32.decode(string: invalidString))

        invalidString = "0"
        XCTAssertThrowsError(try Base32.decode(string: invalidString))

        invalidString = "abc"
        XCTAssertThrowsError(try Base32.decode(string: invalidString))

        let validString = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        XCTAssertNoThrow(try Base32.decode(string: validString))
    }

    func test_decode_throwsOnInvalidPaddedStringLength() {
        XCTAssertNoThrow(try Base32.decode(string: "MZXW6YTBOI======", padded: true))
        XCTAssertThrowsError(try Base32.decode(string: "MZXW6YTBOI=====", padded: true))
        XCTAssertThrowsError(try Base32.decode(string: "MZXW6YTBOI====", padded: true))
        XCTAssertThrowsError(try Base32.decode(string: "MZXW6YTBOI===", padded: true))
        XCTAssertThrowsError(try Base32.decode(string: "MZXW6YTBOI==", padded: true))
        XCTAssertThrowsError(try Base32.decode(string: "MZXW6YTBOI=", padded: true))
        XCTAssertThrowsError(try Base32.decode(string: "MZXW6YTBOI", padded: true))
        XCTAssertThrowsError(try Base32.decode(string: "MZXW6YTBO", padded: true))
        XCTAssertNoThrow(try Base32.decode(string: "MZXW6YTB", padded: true))
    }

    func test_decode_hello() {
        XCTAssertEqual(try Base32.decode(string: "NBSWY3DP"), "hello".data(using: .ascii)!)
    }

    func test_decode_ABCD() {
        XCTAssertEqual(try Base32.decode(string: "IFBEGRA"), "ABCD".data(using: .ascii)!)
    }

    func test_decode_Z() {
        XCTAssertEqual(try Base32.decode(string: "LI", padded: false), "Z".data(using: .ascii)!)
        XCTAssertEqual(try Base32.decode(string: "LI======", padded: true), "Z".data(using: .ascii)!)
    }

    func test_decode_longString() {
        XCTAssertEqual(
            try Base32.decode(
                string: "O5UGC5BAORUGKIJAI5CVIICPKVKCAT2GEBEEKUSFEATCAKY",
                padded: false
            ),
            "what the! GET OUT OF HERE & +".data(using: .ascii)!
        )
        XCTAssertEqual(
            try Base32.decode(
                string: "O5UGC5BAORUGKIJAI5CVIICPKVKCAT2GEBEEKUSFEATCAKY=",
                padded: true
            ),
            "what the! GET OUT OF HERE & +".data(using: .ascii)!
        )
    }

    func test_decode_RFC4648Examples() {
        XCTAssertEqual(try Base32.decode(string: "", padded: true), "".data(using: .ascii)!)
        XCTAssertEqual(try Base32.decode(string: "MY======", padded: true), "f".data(using: .ascii)!)
        XCTAssertEqual(try Base32.decode(string: "MZXQ====", padded: true), "fo".data(using: .ascii)!)
        XCTAssertEqual(try Base32.decode(string: "MZXW6===", padded: true), "foo".data(using: .ascii)!)
        XCTAssertEqual(try Base32.decode(string: "MZXW6YQ=", padded: true), "foob".data(using: .ascii)!)
        XCTAssertEqual(try Base32.decode(string: "MZXW6YTB", padded: true), "fooba".data(using: .ascii)!)
        XCTAssertEqual(try Base32.decode(string: "MZXW6YTBOI======", padded: true), "foobar".data(using: .ascii)!)
    }

    // MARK: Helper Tests

    func testOctetsForQuintet() {
        //
        // 0           1        2         Octet Index
        // +---------+----------+---------+
        // |01234 567|01 23456 7|0123 4567|   Octets Offset
        // +---------+----------+---------+
        // |01110 110|11 00000 1|1111 1010|   Octet Data Bits
        // +---------+----------+---------+
        // |< 1 > < 2| > < 3 > <|.4 > < 5.|>  Quintets
        // +---------+----------+---------+-+
        // |01110|110 11|00000|1 1111|1010  | Quintent Data Bits
        // +-----+------+-----+------+------+
        // 0     1      2      3    4      Quintet Index
        //
        //        let dataBytes: [UInt8] = [0b01110110, 0b11000001, 0b11111010]
        //        let data = Data(dataBytes)

        let quintet0Meta = Base32.octetsForQuintet(0)
        XCTAssertEqual(quintet0Meta.octet1Index, 0)
        XCTAssertEqual(quintet0Meta.octet2Index, nil)
        XCTAssertEqual(quintet0Meta.bitOffset, 0)

        let quintet1Meta = Base32.octetsForQuintet(1)
        XCTAssertEqual(quintet1Meta.octet1Index, 0)
        XCTAssertEqual(quintet1Meta.octet2Index, 1)
        XCTAssertEqual(quintet1Meta.bitOffset, 5)

        let quintet2Meta = Base32.octetsForQuintet(2)
        XCTAssertEqual(quintet2Meta.octet1Index, 1)
        XCTAssertEqual(quintet2Meta.octet2Index, nil)
        XCTAssertEqual(quintet2Meta.bitOffset, 2)

        let quintet3Meta = Base32.octetsForQuintet(3)
        XCTAssertEqual(quintet3Meta.octet1Index, 1)
        XCTAssertEqual(quintet3Meta.octet2Index, 2)
        XCTAssertEqual(quintet3Meta.bitOffset, 7)

        let quintet4Meta = Base32.octetsForQuintet(4)
        XCTAssertEqual(quintet4Meta.octet1Index, 2)
        // note: this does not exist in above example, but is correct for function
        XCTAssertEqual(quintet4Meta.octet2Index, 3)
        XCTAssertEqual(quintet4Meta.bitOffset, 4)
    }

    // swiftformat:disable consecutiveSpaces numberFormatting
    // swiftlint:disable operator_usage_whitespace

    func testCombineUInt8() {
        let aLeading: UInt8   = 0b10100011
        let aTrailing: UInt8  =         0b11001100
        let aCombined: UInt16 = 0b1010001111001100

        let bLeading: UInt8   = 0b00000000
        let bTrailing: UInt8  =         0b11111111
        let bCombined: UInt16 = 0b0000000011111111

        let cLeading: UInt8   = 0b11110000
        let cTrailing: UInt8  =         0b00001111
        let cCombined: UInt16 = 0b1111000000001111

        let dLeading: UInt8   = 0b00001111
        let dTrailing: UInt8  =         0b11110000
        let dCombined: UInt16 = 0b000111111110000

        XCTAssertEqual(Base32.combineUInt8(leadingByte: aLeading, trailingByte: aTrailing), aCombined)
        XCTAssertEqual(Base32.combineUInt8(leadingByte: bLeading, trailingByte: bTrailing), bCombined)
        XCTAssertEqual(Base32.combineUInt8(leadingByte: cLeading, trailingByte: cTrailing), cCombined)
        XCTAssertEqual(Base32.combineUInt8(leadingByte: dLeading, trailingByte: dTrailing), dCombined)
    }

    // swiftlint:enable operator_usage_whitespace
    // swiftformat:enable consecutiveSpaces

    func testGetBitValue() {
        let bits16: UInt16 = 0b0111010011110100

        // 16-bit     = 0111010011110100         = 0b0111010011110100 -> 29940
        // desired    = ---10100--------         = 0b10100            -> 20

        XCTAssertEqual(Base32.getBitValue(numberOfBits: 5, from: bits16, offset: 3), UInt16(0b10100))

        // 16-bit     = 0111010011110100         = 0b0111010011110100 -> 29940
        // desired    = -------------100         = 0b100              -> 4

        XCTAssertEqual(Base32.getBitValue(numberOfBits: 3, from: bits16, offset: 13), UInt16(0b100))
    }

    func testdataTo5BitValueArray() {
        // Example 8-bit byte data:
        // [01110100] [11110111]
        //
        // Broken into 5-bits
        // |01110 100|11 11011 1|
        // |01110|100 11|11011|1 0000|
        // ^^^^ padding 0s

        let bytesA: [UInt8] = [0b01110100, 0b11110111]
        let dataA = Data(bytesA)
        let expectedA: [UInt8] = [0b01110, 0b10011, 0b11011, 0b10000]

        XCTAssertEqual(Base32.dataTo5BitValueArray(data: dataA), expectedA)

        //  Example 8-bit byte data:
        //  [11111111]
        //
        //  Broken into 5-bits
        //  |11111 111|
        //  |11111|111 00|
        //  ^^ padding 0s

        let bytesB: [UInt8] = [0b11111111]
        let dataB = Data(bytesB)
        let expectedB: [UInt8] = [0b11111, 0b11100]

        XCTAssertEqual(Base32.dataTo5BitValueArray(data: dataB), expectedB)
    }

    // swiftformat:enable numberFormatting

    // MARK: Extensions Tests

    func testDataExtension() {
        let data = "Z".data(using: .ascii)!
        XCTAssertEqual(data.base32String(), "LI")
        XCTAssertEqual(data.base32String(padded: true), "LI======")
    }

    func testStringExtension() {
        let string = "MZXW6YTBOI======"
        let data = "foobar".data(using: .ascii)
        XCTAssertEqual(try string.decodeBase32(padded: true), data)
    }
}
