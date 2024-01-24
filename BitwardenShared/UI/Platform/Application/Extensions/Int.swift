import Foundation

// MARK: - TimeInterval

extension Int {
    // MARK: Methods

    /// Creates a string in the format of `HH:mm` from a number of seconds.
    ///
    /// - Parameter shouldSpellOut: Whether `DateComponentsFormatter.UnitsStyle.spellOut`
    /// is applied for accessibility purposes.
    ///
    /// - Returns: A string from a time interval value in the format of `HH:mm`.
    ///
    func timeInHoursMinutes(shouldSpellOut: Bool = false) -> String {
        let formatter = DateComponentsFormatter()
        if shouldSpellOut {
            formatter.unitsStyle = .spellOut
        }
        formatter.allowedUnits = [.hour, .minute]
        formatter.zeroFormattingBehavior = .pad

        guard let date = formatter.string(from: DateComponents(second: Int(self))) else {
            return "\(self)"
        }
        return date
    }
}
