import Foundation

// MARK: - TimeInterval

extension TimeInterval {
    // MARK: Methods

    /// Creates a string from a time interval value in the format of `HH:mm`.
    ///
    /// - Parameter shouldSpellOut: Whether `DateComponentsFormatter.UnitsStyle.spellOut`
    /// is applied for accessibility purposes.
    /// - Returns: The  custom session timeout value as a string formatted in hours and minutes.
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
