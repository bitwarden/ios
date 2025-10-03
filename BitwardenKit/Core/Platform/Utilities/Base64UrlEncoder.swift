import Foundation

extension Data {
    public func base64UrlEncodedString(trimPadding: Bool? = true) -> String {
        let shouldTrim = if trimPadding != nil { trimPadding! } else { true }
        let encoded = base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
        if shouldTrim {
            return encoded.trimmingCharacters(in: CharacterSet(["="]))
        } else {
            return encoded
        }
    }
    
    public init?(base64UrlEncoded str: String) {
        self.init(base64Encoded: normalizeBase64Url(str))
    }
}

private func normalizeBase64Url(_ str: String) -> String {
    let hasPadding = str.last == "="
    let padding = if !hasPadding {
        switch str.count % 4 {
        case 2: "=="
        case 3: "="
        default: ""
        }
    } else { "" }
    return str
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    + padding
}

