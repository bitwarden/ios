#if DEBUG
import BitwardenSdk
import Foundation

enum Fido2DebuggingUtils {
    /// Returns a description of the `authenticatorData` flags part
    /// - Parameter authenticatorData: Authenticator data to retrieve the flags from
    /// - Returns: Formatted string with flags values (0: `false`, 1: `true`)
    static func describeAuthDataFlags(_ authenticatorData: Data) -> String {
        let flagSubdataBytes = [UInt8](authenticatorData.subdata(in: 32 ..< 33))

        let flagByte = flagSubdataBytes[0]
        let flags = [
            "UP: \(flagByte & 0b0000_0001)",
            "UV: \((flagByte & 0b0000_0100) >> 2)",
            "BE: \((flagByte & 0b0000_1000) >> 3)",
            "BS: \((flagByte & 0b0001_0000) >> 4)",
            "AD: \((flagByte & 0b0100_0000) >> 6)",
            "ED: \((flagByte & 0b1000_0000) >> 7)",
        ].joined(separator: " - ")

        return "Flags: \(flags)"
    }
}
#endif
