import BitwardenKit

// MARK: - SessionTimeoutValue

/// An enumeration of session timeout values to choose from.
/// BWA does not use the custom value.
///
extension SessionTimeoutValue: @retroactive CaseIterable {
    /// All of the cases to show in the menu.
    public static let allCases: [Self] = [
        .immediately,
        .oneMinute,
        .fiveMinutes,
        .fifteenMinutes,
        .thirtyMinutes,
        .oneHour,
        .fourHours,
        .onAppRestart,
        .never,
    ]
}
