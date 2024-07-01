#if DEBUG
import BitwardenSdk
import Foundation

enum Fido2DebuggingUtils {
    /// Returns a description of the `authenticatorData` flags part
    /// - Parameter authenticatorData: Authenticator data to retrieve the flags from
    /// - Returns: Formatted string with flags values (0: `false`, 1: `true`)
    static func describeAuthDataFlags(_ authenticatorData: Data) -> String {
        let flagSubdataBytes = [UInt8](authenticatorData.subdata(in: 32 ..< 33))
        var flagsDescribed = "Flags:"

        let flagByte = flagSubdataBytes[0]
        flagsDescribed.append("UP: \(flagByte & 0b0000_0001) - ")
        flagsDescribed.append("UV: \((flagByte & 0b0000_0100) >> 2) - ")
        flagsDescribed.append("BE: \((flagByte & 0b0000_1000) >> 3) - ")
        flagsDescribed.append("BS: \((flagByte & 0b0001_0000) >> 4) - ")
        flagsDescribed.append("AD: \((flagByte & 0b0100_0000) >> 6) - ")
        flagsDescribed.append("ED: \((flagByte & 0b1000_0000) >> 7)")

        return flagsDescribed
    }

    static func describe(request: MakeCredentialRequest) -> String {
        var requestString = ""
        requestString.append("ClientDataHash: ")
        requestString.append(request.clientDataHash.compactMap { String(format: "%02x", $0) }.joined())
        requestString.append("\n")
        requestString.append("RP -> Id: \(request.rp.id) \n")
        let rpName = request.rp.name ?? "nil"
        requestString.append("RP -> Name: \(rpName) \n")
        requestString.append("User -> Id: ")
        requestString.append(request.user.id.compactMap { String(format: "%02x", $0) }.joined())
        requestString.append("\n")
        requestString.append("User -> Name: \(request.user.name) \n")
        requestString.append("User -> DisplayName: \(request.user.displayName) \n")
        requestString.append("PubKeyCredParams: ")
        requestString.append(request.pubKeyCredParams.description)
        requestString.append("\n")
        let excludeList = request.excludeList?.description ?? "nil"
        requestString.append("ExcludeList: \(excludeList) \n")
        requestString.append("Options -> RK: \(request.options.rk) \n")
        requestString.append("Options -> UV: ")
        requestString.append(String(describing: request.options.uv))
        requestString.append("\n")
        let extensions = request.extensions?.description ?? "nil"
        requestString.append("Extensions: \(extensions) \n")
        return requestString
    }

    static func describe(result: MakeCredentialResult) -> String {
        var resultString = ""
        resultString.append("CredentialId: ")
        resultString.append(result.credentialId.compactMap { String(format: "%02x", $0) }.joined())
        resultString.append("\n")
        resultString.append("AuthenticatorData: ")
        resultString.append(result.authenticatorData.compactMap { String(format: "%02x", $0) }.joined())
        resultString.append("\n")
        resultString.append("AttestedCredentialData: ")
        resultString.append(result.attestedCredentialData.compactMap { String(format: "%02x", $0) }.joined())
        resultString.append("\n")
        return resultString
    }
}
#endif
