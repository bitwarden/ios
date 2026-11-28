import Foundation

// MARK: - ProtonAuthenticatorImporter

/// Imports items from an unencrypted Proton Authenticator export.
///
/// Secrets are read the way Proton Authenticator reads them, so imported items generate the same codes.
///
class ProtonAuthenticatorImporter {
    // MARK: Properties

    /// The issuer Proton Authenticator uses for every Steam entry.
    private static let steamIssuer = "Steam"

    // MARK: Methods

    /// Converts a Proton Authenticator export into authenticator items.
    ///
    /// Entries with an unknown type are skipped. A TOTP or Steam entry that can't be read fails the
    /// whole import, so nothing is dropped silently.
    ///
    /// - Parameter data: The contents of the export file.
    /// - Returns: The items to import.
    ///
    static func importItems(data: Data) throws -> [AuthenticatorItemView] {
        let export = try JSONDecoder().decode(ProtonAuthenticatorExport.self, from: data)
        guard let entries = export.entries else {
            throw ProtonAuthenticatorImporterError.passwordProtectedFile
        }
        return try entries.compactMap { entry in
            let item: AuthenticatorItemView?
            switch entry.content.entryType.lowercased() {
            case "steam":
                item = steamItem(from: entry.content)
            case "totp":
                item = totpItem(from: entry.content)
            default:
                return nil
            }
            guard let item else {
                throw ProtonAuthenticatorImporterError.unreadableEntry
            }
            return item
        }
    }

    // MARK: Private

    /// Returns the decoded query parameters of a uri, or `nil` if a value can't be decoded.
    ///
    /// Proton form-encodes the query, so `+` is a space and a literal plus is `%2B`.
    ///
    private static func queryParameters(of components: URLComponents) -> [String: String]? {
        var parameters = [String: String]()
        for item in components.percentEncodedQueryItems ?? [] {
            guard let name = item.name.removingPercentEncoding,
                  let value = (item.value ?? "").replacingOccurrences(of: "+", with: " ").removingPercentEncoding
            else { return nil }
            parameters[name] = value
        }
        return parameters
    }

    /// Cleans a TOTP secret the way Proton's `sanitize_secret` does, uppercasing ASCII letters only,
    /// and returns it as base 32.
    ///
    /// Proton generates codes from the raw bytes of a secret that isn't valid base 32, so such a
    /// secret is stored as the base 32 encoding of those bytes.
    ///
    private static func sanitizedSecret(_ value: String) -> String? {
        var secret = value.filter { !" -_".contains($0) }
        while secret.hasSuffix("=") {
            secret.removeLast()
        }
        secret = String(secret.map { $0.isASCII ? Character($0.uppercased()) : $0 })
        guard !secret.isEmpty else { return nil }
        return secret.isBase32 ? secret : Data(secret.utf8).base32String()
    }

    /// Builds an item from a Proton Steam entry, whose uri is `steam://<secret>`.
    ///
    private static func steamItem(from content: ProtonAuthenticatorContent) -> AuthenticatorItemView? {
        guard let keyIndex = content.uri.steamURIKeyIndexOffset else { return nil }
        var rawSecret = content.uri[keyIndex...].trimmingCharacters(in: .whitespacesAndNewlines)
        while rawSecret.hasSuffix("=") {
            rawSecret.removeLast()
        }
        // Proton writes Steam secrets as uppercase base 32 or, failing that, unpadded base 64.
        // Uppercasing could turn some base 64 secrets into valid-looking base 32, so the case is kept.
        let secret: String
        if rawSecret.isBase32 {
            secret = rawSecret
        } else {
            let padding = String(repeating: "=", count: (4 - rawSecret.count % 4) % 4)
            guard let data = Data(base64Encoded: rawSecret + padding), !data.isEmpty else { return nil }
            secret = data.base32String()
        }
        return AuthenticatorItemView(
            favorite: false,
            id: UUID().uuidString,
            name: steamIssuer,
            totpKey: "steam://\(secret)",
            username: content.name?.trimmingCharacters(in: .whitespaces).nilIfEmpty
                .flatMap { $0 == steamIssuer ? nil : $0 },
        )
    }

    /// Builds an item from a Proton TOTP entry.
    ///
    /// Proton writes only the account into the uri label and the issuer into the query, so the
    /// label isn't run through `OTPAuthModel(otpAuthUri:)`, which expects an `issuer:` prefix.
    ///
    private static func totpItem(from content: ProtonAuthenticatorContent) -> AuthenticatorItemView? {
        guard let components = URLComponents(string: content.uri),
              components.scheme?.lowercased() == "otpauth",
              components.host?.lowercased() == "totp",
              let parameters = queryParameters(of: components),
              let secret = parameters["secret"].flatMap(sanitizedSecret)
        else { return nil }

        var algorithm = TOTPCryptoHashAlgorithm.sha1
        if let value = parameters["algorithm"] {
            guard let parsed = TOTPCryptoHashAlgorithm(rawValue: value.uppercased()) else { return nil }
            algorithm = parsed
        }
        var digits = 6
        if let value = parameters["digits"] {
            guard let parsed = Int(value), (5 ... 10).contains(parsed) else { return nil }
            digits = parsed
        }
        var period = 30
        if let value = parameters["period"] {
            guard let parsed = Int(value), parsed > 0 else { return nil }
            period = parsed
        }

        let label = components.path.drop { $0 == "/" }.trimmingCharacters(in: .whitespaces)
        let entryName = content.name?.trimmingCharacters(in: .whitespaces).nilIfEmpty
        let name = parameters["issuer"]?.trimmingCharacters(in: .whitespaces).nilIfEmpty ?? entryName ?? label
        let account = label.hasPrefix("\(name):")
            ? label.dropFirst(name.count + 1).trimmingCharacters(in: .whitespaces)
            : label
        let accountName = (account.nilIfEmpty ?? entryName).flatMap { $0 == name ? nil : $0 }
        let otp = OTPAuthModel(
            accountName: accountName,
            algorithm: algorithm,
            digits: digits,
            issuer: name,
            period: period,
            secret: secret,
        )
        return AuthenticatorItemView(
            favorite: false,
            id: UUID().uuidString,
            name: name,
            totpKey: otp.otpAuthUri,
            username: accountName,
        )
    }
}

// MARK: - ProtonAuthenticatorExport

/// The top level of a Proton Authenticator export.
///
/// A password-protected export has a `salt` and an encrypted `content` instead of `entries`.
///
struct ProtonAuthenticatorExport: Decodable {
    // MARK: Types

    /// The keys used to decode the export.
    enum CodingKeys: String, CodingKey {
        case entries
        case salt
        case version
    }

    // MARK: Properties

    /// The entries in the export, or `nil` if the export is password protected.
    let entries: [ProtonAuthenticatorEntry]?

    // MARK: Initialization

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .version)
        guard version == 1 else {
            throw DecodingError.dataCorruptedError(
                forKey: .version,
                in: container,
                debugDescription: "Unsupported Proton Authenticator export version \(version).",
            )
        }
        if container.contains(.salt), !container.contains(.entries) {
            entries = nil
        } else {
            entries = try container.decode([ProtonAuthenticatorEntry].self, forKey: .entries)
        }
    }
}

/// A single entry in a Proton Authenticator export.
///
struct ProtonAuthenticatorEntry: Decodable {
    /// The OTP details of the entry.
    let content: ProtonAuthenticatorContent
}

/// The OTP details of a Proton Authenticator entry.
///
struct ProtonAuthenticatorContent: Decodable {
    // MARK: Types

    /// The keys used to decode the content.
    enum CodingKeys: String, CodingKey {
        case entryType = "entry_type"
        case name
        case uri
    }

    // MARK: Properties

    /// The entry type, `Totp` or `Steam`.
    let entryType: String

    /// The display name: the account for TOTP entries, the user-given name for Steam entries.
    let name: String?

    /// An `otpauth://totp/` uri, or `steam://<secret>` for Steam entries.
    let uri: String
}

// MARK: - ProtonAuthenticatorImporterError

/// Errors thrown while importing a Proton Authenticator export.
///
enum ProtonAuthenticatorImporterError: Error, Equatable {
    /// The export is password protected, which isn't supported.
    case passwordProtectedFile

    /// A TOTP or Steam entry has a uri, secret or parameter that can't be read.
    case unreadableEntry
}
