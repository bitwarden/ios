import Foundation
import Testing

@testable import BitwardenKit

struct UnknownEnumValueErrorTests {
    // MARK: Types

    /// An `Int` raw-value enum, like most server enums.
    enum Fruit: Int {
        case apple = 1
    }

    /// A `String` raw-value enum.
    enum Color: String {
        case red
    }

    // MARK: Tests

    /// `errorDomain` includes the enum name so each enum is grouped separately in Crashlytics.
    @Test
    func errorDomain() {
        let subject = UnknownEnumValueError(enumName: "CipherType", rawValue: "99", itemId: "1")

        #expect(UnknownEnumValueError.errorDomain == "Unknown Enum Value")
        #expect(subject.errorDomain == "Unknown Enum Value: CipherType")
    }

    /// `errorCode` is the same for every enum.
    @Test
    func errorCode() {
        #expect(UnknownEnumValueError(enumName: "CipherType", rawValue: "99").errorCode == 5000)
        #expect(UnknownEnumValueError(enumName: "PolicyType", rawValue: "42").errorCode == 5000)
    }

    /// `errorUserInfo` contains the raw value and item ID.
    @Test
    func errorUserInfo() {
        let subject = UnknownEnumValueError(enumName: "CipherType", rawValue: "99", itemId: "1")

        #expect(subject.errorUserInfo.count == 2)
        #expect(subject.errorUserInfo["RawValue"] as? String == "99")
        #expect(subject.errorUserInfo["ItemId"] as? String == "1")
    }

    /// `errorUserInfo` omits the item ID if there isn't one.
    @Test
    func errorUserInfo_noItemId() {
        let subject = UnknownEnumValueError(enumName: "CipherType", rawValue: "99")

        #expect(subject.errorUserInfo.count == 1)
        #expect(subject.errorUserInfo["RawValue"] as? String == "99")
        #expect(subject.errorUserInfo["ItemId"] == nil)
    }

    /// Bridging to `NSError` uses the enum-specific domain, code, and user info, which is what
    /// Crashlytics records.
    @Test
    func nsError() {
        let error: Error = UnknownEnumValueError(enumName: "CipherType", rawValue: "99", itemId: "1")
        let nsError = error as NSError

        #expect(nsError.domain == "Unknown Enum Value: CipherType")
        #expect(nsError.code == 5000)
        #expect(nsError.userInfo["RawValue"] as? String == "99")
        #expect(nsError.userInfo["ItemId"] as? String == "1")
    }

    /// `init(_:rawValue:itemId:)` derives the enum name from the type.
    @Test
    func init_type() {
        #expect(
            UnknownEnumValueError(Fruit.self, rawValue: 99, itemId: "1")
                == UnknownEnumValueError(enumName: "Fruit", rawValue: "99", itemId: "1"),
        )
        #expect(
            UnknownEnumValueError(Color.self, rawValue: "purple")
                == UnknownEnumValueError(enumName: "Color", rawValue: "purple"),
        )
    }

    /// `init(_:itemId:)` creates an error from an unknown `OpenEnum` value.
    @Test
    func init_openEnum_unknown() {
        let value = OpenEnum<Fruit>.unknown(99)

        #expect(
            UnknownEnumValueError(value, itemId: "1")
                == UnknownEnumValueError(enumName: "Fruit", rawValue: "99", itemId: "1"),
        )
    }

    /// `init(_:itemId:)` returns `nil` for a known or missing `OpenEnum` value.
    @Test
    func init_openEnum_knownOrMissing() {
        #expect(UnknownEnumValueError(OpenEnum<Fruit>.known(.apple), itemId: "1") == nil)
        #expect(UnknownEnumValueError(OpenEnum<Fruit>?.none, itemId: "1") == nil)
    }
}
