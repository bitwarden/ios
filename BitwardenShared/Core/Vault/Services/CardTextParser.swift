import BitwardenKit
import Foundation

// MARK: - CardTextParser

/// Parses raw OCR text lines extracted from a payment card scan into structured card data.
///
protocol CardTextParser: AnyObject { // sourcery: AutoMockable
    /// Parses a collection of OCR text strings and returns the best-matching `ScannedCardData`.
    ///
    /// - Parameter lines: The raw text lines recognized by the scanner.
    /// - Returns: A `ScannedCardData` populated with whatever fields could be confidently detected.
    func parseCard(lines: [String]) -> ScannedCardData
}

// MARK: - DefaultCardTextParser

/// Default implementation of `CardTextParser` that uses regex-based extraction.
///
final class DefaultCardTextParser: CardTextParser {
    // MARK: Private Constants

    /// Regex that matches a payment card number: 13–19 digit groups optionally separated by spaces or dashes.
    private static let cardNumberRegex = try? NSRegularExpression(
        pattern: #"(?<!\d)(\d[ \-]?){12,18}\d(?!\d)"#,
    )

    /// Regex that matches an expiry date in MM/YY or MM/YYYY format. The year is either two or four
    /// digits — a three digit run is OCR noise rather than a year, and must not be accepted.
    private static let expiryRegex = try? NSRegularExpression(
        pattern: #"\b(0?[1-9]|1[0-2])\s*/\s*(\d{2}|\d{4})\b"#,
    )

    /// The most digits a payment card number can have.
    private static let maximumCardNumberDigits = 19

    /// The fewest digits a payment card number can have. Doubles as the threshold that separates a
    /// card number from an expiration date, since an expiry carries only four to six digits.
    private static let minimumCardNumberDigits = 13

    // MARK: Properties

    /// Provides the present time, used to bound a scanned expiration year to a plausible range.
    private let timeProvider: TimeProvider

    // MARK: Initialization

    /// Initializes a `DefaultCardTextParser`.
    ///
    /// - Parameter timeProvider: Provides the present time, used to bound a scanned expiration year
    ///     to a plausible range.
    ///
    init(timeProvider: TimeProvider) {
        self.timeProvider = timeProvider
    }

    // MARK: CardTextParser

    func parseCard(lines: [String]) -> ScannedCardData {
        var result = ScannedCardData()

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
                result.cardNumber = number
                break
            }
        }

        // Only merge fragments when no card number was found on a single line.
        if result.cardNumber == nil {
            let mergedLines = mergeCardNumberFragments(from: flatLines)
            for line in mergedLines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if let number = extractCardNumber(from: trimmed) {
                    result.cardNumber = number
                    break
                }
            }
        }

        // Expiry is extracted from the flat (unmerged) lines.
        for line in flatLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Always overwrite with the latest match so that when a card shows both a
            // "valid from" and a "valid thru" date we end up with the expiry, not the start date.
            if let (month, year) = extractExpiry(from: trimmed) {
                result.expirationMonth = month
                result.expirationYear = year
            }
        }

        return result
    }

    // MARK: Private Methods

    /// Extracts a card number from a line of text, returning digits only (no spaces/dashes).
    private func extractCardNumber(from line: String) -> String? {
        guard let regex = Self.cardNumberRegex else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: range) else { return nil }
        let matchRange = Range(match.range, in: line)!
        let raw = String(line[matchRange])
        let digits = raw.filter(\.isNumber)
        guard digits.count >= Self.minimumCardNumberDigits,
              digits.count <= Self.maximumCardNumberDigits else { return nil }
        // Reject sequences that look like dates or years (e.g. 8-digit numbers that match no Luhn prefix)
        guard !looksLikeDateOrYear(digits) else { return nil }
        guard isLuhnValid(digits), hasValidLength(digits) else { return nil }
        return digits
    }

    /// Extracts an expiry month (1–12) and 4-digit year from a line of text.
    ///
    /// A line carrying as many digits as a card number is skipped entirely. OCR routinely reads a
    /// digit, or a group separator, inside a card number as `/`, which leaves behind something shaped
    /// exactly like an expiry — `"5/33 6195 0371 5702"` parses as May 2033 despite no date being
    /// printed on the card. A card number carries at least 13 digits and an expiry carries four to
    /// six, so the digit count tells them apart. A genuine expiry that OCR merged onto the same line
    /// as the card number is skipped too; leaving the field empty is the safer of the two failures.
    ///
    /// Of the remaining matches the last plausible one wins, so a card printing both a "valid from"
    /// and a "valid thru" date yields the expiry rather than the start date.
    private func extractExpiry(from line: String) -> (month: Int, year: String)? {
        guard let regex = Self.expiryRegex,
              line.filter(\.isNumber).count < Self.minimumCardNumberDigits
        else { return nil }

        let range = NSRange(line.startIndex..., in: line)
        var result: (month: Int, year: String)?

        for match in regex.matches(in: line, range: range) {
            guard match.numberOfRanges == 3,
                  let monthRange = Range(match.range(at: 1), in: line),
                  let yearRange = Range(match.range(at: 2), in: line),
                  let month = Int(String(line[monthRange]))
            else { continue }

            var yearString = String(line[yearRange])
            if yearString.count == 2 {
                yearString = "20\(yearString)"
            }

            // Skip rather than stop: a later match on the line may still be a genuine expiry.
            guard isPlausibleExpiryYear(yearString) else { continue }

            result = (month, yearString)
        }

        return result
    }

    /// Returns `true` if `yearString` falls within the plausible range for a card expiration year.
    private func isPlausibleExpiryYear(_ yearString: String) -> Bool {
        guard let year = Int(yearString) else { return false }
        let currentYear = Calendar.current.component(.year, from: timeProvider.presentTime)
        return year >= currentYear - Constants.cardScanMaxExpiryYearsPast
            && year <= currentYear + Constants.cardScanMaxExpiryYearsAhead
    }

    /// Merges adjacent lines that look like split card-number digit groups into a single line.
    ///
    /// OCR engines sometimes break a card number row (e.g. `"4111 1111 1111 1111"`) across
    /// multiple lines. A line qualifies as a card-number fragment when it contains only digits,
    /// spaces, and dashes, and every whitespace-separated group is ≤ 4 digits long.
    /// Consecutive fragment lines are joined with a space so the card-number regex can match them.
    private func mergeCardNumberFragments(from lines: [String]) -> [String] {
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
    private func looksLikeDateOrYear(_ digits: String) -> Bool {
        // Reject 8-digit strings that look like MMDDYYYY or YYYYMMDD
        if digits.count == 8 {
            return true
        }
        return false
    }

    /// Returns `true` if `digits` has a length valid for the brand detected from its leading digits.
    private func hasValidLength(_ digits: String) -> Bool {
        CardComponent.Brand.detect(from: digits).validDigitLengths.contains(digits.count)
    }

    /// Returns `true` if `digits` satisfies the Luhn mod-10 checksum.
    private func isLuhnValid(_ digits: String) -> Bool {
        var sum = 0
        for (index, char) in digits.reversed().enumerated() {
            guard var digit = char.wholeNumberValue else { return false }
            if !index.isMultiple(of: 2) {
                digit *= 2
                if digit > 9 { digit -= 9 }
            }
            sum += digit
        }
        return sum.isMultiple(of: 10)
    }
}
