import Foundation

// MARK: - DomainNameError

/// Errors thrown by `DomainName`.
///
enum DomainNameError: Error {
    /// The data file containing the list of URL suffixes wasn't able to be loaded.
    case unableToLoadDataFile
}

// MARK: - DomainName

/// A helper class that parses the domain parts of a URL. This can be used to separate the top-level
/// domain from any second-level or subdomains.
///
/// Example:
/// - https://sub.example.co.uk
///     - Top-level domain: co.uk
///     - Second-level domain: example
///     - Subdomain: sub
///     - Base domain: example.co.uk
///
class DomainName {
    // MARK: Types

    /// A data model containing the data loaded from the suffix list.
    ///
    struct DataSet: Equatable {
        /// The list of exception rules.
        let exceptions: Set<String>

        /// The list of normal rules.
        let normals: Set<String>

        /// The list of wildcard rules.
        let wildcards: Set<String>

        /// Determines if the domain matches the specified rule.
        ///
        /// - Parameters:
        ///   - domain: The domain to check for a match.
        ///   - ruleType: The rule to match against.
        /// - Returns: Whether the domain matches the rule.
        ///
        func isMatch(for domain: String, ruleType: RuleType) -> Bool {
            switch ruleType {
            case .exception:
                exceptions.contains(domain)
            case .normal:
                normals.contains(domain)
            case .wildcard:
                wildcards.contains(domain)
            }
        }
    }

    /// A data model containing the result of parsing the URL.
    ///
    struct DomainNameResult: Equatable {
        /// The top-level domain (TLD) of the URL.
        let topLevelDomain: String

        /// The second-level domain of the URL.
        let secondLevelDomain: String

        /// The subdomain of the URL.
        let subDomain: String

        /// The domain of the URL, constructed from the second-level and top-level domains.
        var domain: String {
            "\(secondLevelDomain).\(topLevelDomain)"
        }
    }

    /// An enumeration of the types of rules contained within the suffix list.
    ///
    enum RuleType: CaseIterable {
        /// An exception rule.
        case exception

        /// A normal rule.
        case normal

        /// A wildcard rule.
        case wildcard
    }

    // MARK: Static Properties

    /// A cached version of the data set.
    private(set) static var dataSet: DataSet?

    // MARK: Methods

    /// Loads the data set from a URL.
    ///
    /// Note: It isn't necessary to call this - by default the data set will be loaded from the
    /// app's bundle.
    ///
    /// - Parameter url: The URL to the suffix list file to load.
    ///
    static func loadDataSet(url: URL) throws {
        let data = try Data(contentsOf: url)
        try loadDataSet(data: data)
    }

    /// Loads the data set from a data object.
    ///
    /// Note: It isn't necessary to call this - by default the data set will be loaded from the
    /// app's bundle.
    ///
    /// - Parameter data: The data for a suffix list to load.
    ///
    static func loadDataSet(data: Data) throws {
        dataSet = try parseData(data)
    }

    /// Parses the base domain from the URL.
    ///
    /// - Parameter url: The URL to parse.
    /// - Returns: The URL's base domain.
    ///
    static func parseBaseDomain(url: URL) -> String? {
        parseURL(url)?.domain
    }

    /// Parses a URL to get the breakdown of a URL's domain.
    ///
    /// - Parameter url: The URL to parse.
    /// - Returns: A struct containing the subdomain, second-level domain and top-level domain.
    ///
    static func parseURL(_ url: URL) -> DomainNameResult? {
        guard let dataSet = dataSet ?? (try? loadDataSetFromBundle()),
              let host = url.host?.lowercased()
        else { return nil }

        // Split the host into parts separated by a period. Start with the last part and
        // incrementally add back the earlier parts to build a list of any matching domains in the
        // data set.
        let hostParts = host.components(separatedBy: ".").reversed()

        var partialDomain = ""
        var ruleMatches = [(RuleType, String)]()
        for hostPart in hostParts {
            if partialDomain.isEmpty {
                partialDomain = hostPart
            } else {
                partialDomain = "\(hostPart).\(partialDomain)"
            }

            for rule in RuleType.allCases {
                guard dataSet.isMatch(for: partialDomain, ruleType: rule) else { continue }
                ruleMatches.append((rule, partialDomain))
            }
        }

        // Sort the matches, the rule with the longest number of parts wins.
        let countOfParts: (String) -> Int = { string in
            string.split(separator: ".").count
        }
        guard let result = ruleMatches.max(by: { countOfParts($0.1) < countOfParts($1.1) }) else { return nil }

        // Determine the position of the TLD within the host.
        let tldIndex: Range<Substring.Index>?
        switch result.0 {
        case .exception:
            tldIndex = host.range(of: "." + result.1, options: .backwards)
        case .normal:
            tldIndex = host.range(of: "." + result.1, options: .backwards)
        case .wildcard:
            // This gets the last portion of the TLD.
            guard let nonWildcardTldIndex = host.range(of: "." + result.1, options: .backwards) else {
                tldIndex = nil
                break
            }
            let nonWildcardTld = host.prefix(upTo: nonWildcardTldIndex.lowerBound)
            // But we need to also match the wildcard portion.
            tldIndex = nonWildcardTld.range(of: ".", options: .backwards)
        }

        guard let tldIndex else { return nil }
        let topLevelDomain = String(host.suffix(from: host.index(after: tldIndex.lowerBound)))

        // Parse the remaining parts prior to the TLD.
        // - If there's 0 parts left, there is just a TLD and no domain or subdomain.
        // - If there's 1 part, it's the domain, and there is no subdomain
        // - If there's 2+ parts, the last part is the domain, the other parts (combined) are the subdomain.
        let possibleSubDomainAndDomain = String(host.prefix(upTo: tldIndex.lowerBound))
        var subDomainAndDomainParts = possibleSubDomainAndDomain.split(separator: ".")
        let secondLevelDomain = subDomainAndDomainParts.popLast()
        let subDomain = subDomainAndDomainParts.joined(separator: ".")

        return DomainNameResult(
            topLevelDomain: topLevelDomain,
            secondLevelDomain: String(secondLevelDomain ?? ""),
            subDomain: String(subDomain)
        )
    }

    // MARK: Private

    /// Loads the data set from the app's bundle.
    ///
    private static func loadDataSetFromBundle() throws -> DataSet? {
        let url = Bundle(for: DomainName.self).url(forResource: "public_suffix_list", withExtension: "dat")
        guard let url else { throw DomainNameError.unableToLoadDataFile }
        try loadDataSet(url: url)
        return dataSet
    }

    /// Parses a data object containing the list of suffixes.
    ///
    /// - Parameter data: The data object containing the list of suffixes.
    /// - Returns: A parsed `DataSet` from the data instance.
    ///
    private static func parseData(_ data: Data) throws -> DataSet {
        guard let string = String(data: data, encoding: .utf8), !string.isEmpty else {
            throw DomainNameError.unableToLoadDataFile
        }

        var exceptions = [String]()
        var normals = [String]()
        var wildcards = [String]()

        for line in string.components(separatedBy: .newlines) {
            // Strip out any comment or whitespace lines.
            guard !line.starts(with: "//"),
                  !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                continue
            }

            // Determine the rule type, and remove anything other than the TLD.
            if line.starts(with: "*") {
                // Drop "*.".
                wildcards.append(String(line.dropFirst(2)))
            } else if line.starts(with: "!") {
                // Drop "!".
                exceptions.append(String(line.dropFirst()))
            } else {
                normals.append(line)
            }
        }

        return DataSet(
            exceptions: Set(exceptions),
            normals: Set(normals),
            wildcards: Set(wildcards)
        )
    }
}
