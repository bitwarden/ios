import Foundation

// MARK: - CardTextParser

/// Parses raw OCR text lines extracted from a payment card scan into structured card data.
///
enum CardTextParser {
    // MARK: Private Constants

    /// Labels printed on cards that should not be interpreted as cardholder names.
    private static let ignoredNameLines: Set<String> = [
        "VALID THRU",
        "VALID FROM",
        "VALID DATES",
        "MEMBER SINCE",
        "GOOD THRU",
        "GOOD FROM",
        "EXPIRES END",
        "CREDIT CARD",
        "DEBIT CARD",
        "PREPAID CARD",
        "PLATINUM",
        "GOLD",
        "CLASSIC",
        "STANDARD",
        "BUSINESS",
        "SIGNATURE",
        "PREFERRED",
        "REWARDS",
        "CASHBACK",
        "INFINITE",
        "WORLD",
        "ICON",
    ]

    /// Regex that matches a payment card number: 13–19 digit groups optionally separated by spaces or dashes.
    private static let cardNumberRegex = try? NSRegularExpression(
        pattern: #"(?<!\d)(\d[ \-]?){12,18}\d(?!\d)"#,
    )

    /// Regex that matches an expiry date in MM/YY or MM/YYYY format.
    private static let expiryRegex = try? NSRegularExpression(
        pattern: #"\b(0?[1-9]|1[0-2])\s*/\s*(\d{2,4})\b"#,
    )

    // MARK: Internal Methods

    /// Parses a collection of OCR text strings and returns the best-matching `ScannedCardData`.
    ///
    /// - Parameter lines: The raw text lines recognized by the scanner.
    /// - Returns: A `ScannedCardData` populated with whatever fields could be confidently detected.
    static func parse(lines: [String]) -> ScannedCardData {
        var result = ScannedCardData()

        print("\n[CardTextParser] Parsing \(lines.count) lines: \(lines)")

        // Flatten embedded newlines: OCR transcripts can contain \n within a single
        // recognized region. Split here so all downstream logic works on single-line strings.
        // Empty or whitespace-only lines are discarded immediately — they carry no useful data.
        let flatLines = lines
            .flatMap { $0.components(separatedBy: "\n") }
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        // Card number: try each line as-is first. Merging digit-fragment lines is deferred
        // until needed because an adjacent CVV line (e.g. Amex's 4-digit CID) could otherwise
        // be folded into the card number string.
        for line in flatLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let number = extractCardNumber(from: trimmed) {
                print("[CardTextParser] cardNumber matched on line '\(trimmed)': \(number)")
                result.cardNumber = number
                break
            }
        }

        // Only merge fragments when no card number was found on a single line.
        if result.cardNumber == nil {
            let mergedLines = mergeCardNumberFragments(from: flatLines)
            print("[CardTextParser] No card number found on single lines — retrying with merged fragments: \(mergedLines)")
            for line in mergedLines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if let number = extractCardNumber(from: trimmed) {
                    print("[CardTextParser] cardNumber matched on merged line '\(trimmed)': \(number)")
                    result.cardNumber = number
                    break
                }
            }
        }

        // Expiry and name are always extracted from the flat (unmerged) lines.
        for line in flatLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Always overwrite with the latest match so that when a card shows both a
            // "valid from" and a "valid thru" date we end up with the expiry, not the start date.
            if let (month, year) = extractExpiry(from: trimmed) {
                print("[CardTextParser] expiry matched on line '\(trimmed)': month=\(month), year=\(year)")
                result.expirationMonth = month
                result.expirationYear = year
            }

            for name in extractName(from: trimmed) where !result.cardholderNameCandidates.contains(name) {
                print("[CardTextParser] cardholderName candidate on line '\(trimmed)': \(name)")
                result.cardholderNameCandidates.append(name)
            }
        }

        // Second pass: combine adjacent flat lines in case a first/last name is split across them.
        for index in 0 ..< (flatLines.count - 1) {
            let combined = flatLines[index].trimmingCharacters(in: .whitespaces)
                + " "
                + flatLines[index + 1].trimmingCharacters(in: .whitespaces)
            for name in extractName(from: combined) where !result.cardholderNameCandidates.contains(name) {
                print("[CardTextParser] cardholderName candidate (combined lines \(index)+\(index + 1)) '\(combined)': \(name)")
                result.cardholderNameCandidates.append(name)
            }
        }

        print("[CardTextParser] Result: \(result)")
        return result
    }

    // MARK: Private Methods

    /// Extracts a card number from a line of text, returning digits only (no spaces/dashes).
    private static func extractCardNumber(from line: String) -> String? {
        guard let regex = cardNumberRegex else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: range) else { return nil }
        let matchRange = Range(match.range, in: line)!
        let raw = String(line[matchRange])
        let digits = raw.filter(\.isNumber)
        guard digits.count >= 13, digits.count <= 19 else { return nil }
        // Reject sequences that look like dates or years (e.g. 8-digit numbers that match no Luhn prefix)
        guard !looksLikeDateOrYear(digits) else { return nil }
        return digits
    }

    /// Extracts an expiry month (1–12) and 4-digit year from a line of text.
    private static func extractExpiry(from line: String) -> (month: Int, year: String)? {
        guard let regex = expiryRegex else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        let allMatches = regex.matches(in: line, range: range)
        guard let match = allMatches.last,
              match.numberOfRanges == 3 else { return nil }
        guard
            let monthRange = Range(match.range(at: 1), in: line),
            let yearRange = Range(match.range(at: 2), in: line),
            let month = Int(String(line[monthRange]))
        else { return nil }

        var yearString = String(line[yearRange])
        if yearString.count == 2 {
            yearString = "20\(yearString)"
        }
        return (month, yearString)
    }

    /// Extracts all cardholder name candidates from a line of text.
    ///
    /// The line must be all-uppercase and contain only letters, spaces, and hyphens.
    /// All contiguous subsequences of two or more words are returned as candidates,
    /// excluding any that match known card labels (e.g. "VALID THRU", "EUR CURRENCY").
    /// This lets the caller surface every plausible name slice from a multi-word line
    /// (e.g. "J SMITH EUR CURRENCY" yields "J SMITH", "SMITH EUR",
    /// "EUR CURRENCY", "J SMITH EUR", "SMITH EUR CURRENCY", "J SMITH EUR CURRENCY").
    private static func extractName(from line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        // Must be uppercase only (letters + spaces + hyphens for hyphenated names)
        guard trimmed == trimmed.uppercased() else { return [] }
        // Must contain only letters, spaces, and hyphens
        let allowedChars = CharacterSet.letters.union(.init(charactersIn: " -"))
        guard trimmed.unicodeScalars.allSatisfy({ allowedChars.contains($0) }) else { return [] }
        let words = trimmed.split(separator: " ").map(String.init)
        guard words.count >= 2 else { return [] }

        // Collect every contiguous subsequence of 2+ words that isn't a known label.
        var candidates: [String] = []
        for start in 0 ..< words.count {
            for end in (start + 1) ..< words.count {
                let candidate = words[start ... end].joined(separator: " ")
                guard !ignoredNameLines.contains(candidate) else { continue }
                candidates.append(candidate)
            }
        }
        return candidates
    }

    /// Merges adjacent lines that look like split card-number digit groups into a single line.
    ///
    /// OCR engines sometimes break a card number row (e.g. `"4111 1111 1111 1111"`) across
    /// multiple lines. A line qualifies as a card-number fragment when it contains only digits,
    /// spaces, and dashes, and every whitespace-separated group is ≤ 4 digits long.
    /// Consecutive fragment lines are joined with a space so the card-number regex can match them.
    private static func mergeCardNumberFragments(from lines: [String]) -> [String] {
        let cardFragmentChars = CharacterSet.decimalDigits.union(.init(charactersIn: " -"))

        func isFragment(_ line: String) -> Bool {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  trimmed.unicodeScalars.allSatisfy({ cardFragmentChars.contains($0) }) else {
                return false
            }
            // Each group must be 1–6 digits: standard cards use groups of 4,
            // Amex uses 4-6-5 grouping so the middle group can be up to 6 digits.
            let groups = trimmed.split(separator: " ")
            return !groups.isEmpty && groups.allSatisfy { $0.count <= 6 && $0.allSatisfy(\.isNumber) }
        }

        var result: [String] = []
        var index = 0
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if isFragment(trimmed) {
                var merged = trimmed
                var next = index + 1
                while next < lines.count {
                    let nextTrimmed = lines[next].trimmingCharacters(in: .whitespaces)
                    guard isFragment(nextTrimmed) else { break }
                    merged += " " + nextTrimmed
                    next += 1
                }
                result.append(merged)
                index = next
            } else {
                result.append(trimmed)
                index += 1
            }
        }
        return result
    }

    /// Returns `true` if a digit string looks like a date, year, or other non-card-number sequence.
    private static func looksLikeDateOrYear(_ digits: String) -> Bool {
        // Reject 8-digit strings that look like MMDDYYYY or YYYYMMDD
        if digits.count == 8 {
            return true
        }
        return false
    }
}
