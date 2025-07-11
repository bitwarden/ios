@testable import BitwardenShared

// MARK: - VaultListSection

extension VaultListSection {
    /// Returns a string containing a description of the vault list section.
    /// - Returns: The dumped description of the section.
    func dump() -> String {
        var result = ""
        result.append("Section[\(id)]: \(name)\n")
        result.append(items.dump(indent: "  "))
        return result
    }
}

// MARK: - VaultListItem

extension VaultListItem {
    /// Returns a string containing a description of the vault list item.
    /// - Parameter indent: The indent to apply on the dumped string.
    /// - Returns: The dumped description of the item.
    func dump(indent: String = "") -> String {
        var result = ""
        switch itemType {
        case let .cipher(cipher, _):
            result.append(indent + "- Cipher: \(cipher.name)")
        case let .group(group, count):
            result.append(indent + "- Group[\(id)]: \(group.name) (\(count))")
        case let .totp(name, model):
            result.append(indent + "- TOTP: \(model.id) \(name) \(model.totpCode.displayCode)")
        }
        return result
    }
}

// MARK: - Array of VaultListSection

extension [VaultListSection] {
    /// Returns a string containing a description of the array of vault list sections.
    /// - Returns: The dumped description of the sections array.
    func dump() -> String {
        reduce(into: "") { result, section in
            result.append(section.dump())
            if section != last {
                result.append("\n")
            }
        }
    }
}

// MARK: - Array of VaultListItem

extension [VaultListItem] {
    /// Returns a string containing a description of the array of vault list items.
    /// - Parameter indent: The indent to apply on the dumped string.
    /// - Returns: The dumped description of the items array.
    func dump(indent: String = "") -> String {
        guard !isEmpty else { return indent + "(empty)" }
        return reduce(into: "") { result, item in
            result.append(item.dump(indent: indent))
            if item != last {
                result.append("\n")
            }
        }
    }
}
