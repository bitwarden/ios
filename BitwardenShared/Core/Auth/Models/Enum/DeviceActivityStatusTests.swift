import BitwardenKitMocks
import BitwardenResources
import Foundation
import Testing

@testable import BitwardenShared

// MARK: - DeviceActivityStatusTests

struct DeviceActivityStatusTests {
    // MARK: Properties

    var timeProvider: MockTimeProvider

    // MARK: Initialization

    init() {
        timeProvider = MockTimeProvider(.mockTime(Date(timeIntervalSince1970: 1_718_000_000)))
    }

    // MARK: Tests

    /// `init(from:timeProvider:)` returns `.unknown` when the date is nil.
    @Test
    func init_nilDate() {
        #expect(DeviceActivityStatus(from: nil, timeProvider: timeProvider) == .unknown)
    }

    /// `init(from:timeProvider:)` returns `.unknown` when the date is in the future.
    @Test
    func init_futureDate() {
        let futureDate = timeProvider.presentTime.addingTimeInterval(3600)
        #expect(DeviceActivityStatus(from: futureDate, timeProvider: timeProvider) == .unknown)
    }

    /// `init(from:timeProvider:)` returns `.today` when the date is today (0 days ago).
    @Test
    func init_today() {
        let date = timeProvider.presentTime.addingTimeInterval(-3600)
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .today)
    }

    /// `init(from:timeProvider:)` returns `.thisWeek` at the 1-day boundary.
    @Test
    func init_thisWeek_lowerBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -1, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .thisWeek)
    }

    /// `init(from:timeProvider:)` returns `.thisWeek` at the 6-day boundary.
    @Test
    func init_thisWeek_upperBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -6, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .thisWeek)
    }

    /// `init(from:timeProvider:)` returns `.lastWeek` at the 7-day boundary.
    @Test
    func init_lastWeek_lowerBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -7, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .lastWeek)
    }

    /// `init(from:timeProvider:)` returns `.lastWeek` at the 13-day boundary.
    @Test
    func init_lastWeek_upperBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -13, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .lastWeek)
    }

    /// `init(from:timeProvider:)` returns `.thisMonth` at the 14-day boundary.
    @Test
    func init_thisMonth_lowerBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -14, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .thisMonth)
    }

    /// `init(from:timeProvider:)` returns `.thisMonth` at the 29-day boundary.
    @Test
    func init_thisMonth_upperBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -29, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .thisMonth)
    }

    /// `init(from:timeProvider:)` returns `.overThirtyDaysAgo` at the 30-day boundary.
    @Test
    func init_overThirtyDaysAgo_lowerBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -30, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .overThirtyDaysAgo)
    }

    /// `localizedString` returns the correct value for each status.
    @Test
    func localizedString() {
        #expect(DeviceActivityStatus.today.localizedString == Localizations.today)
        #expect(DeviceActivityStatus.thisWeek.localizedString == Localizations.pastSevenDays)
        #expect(DeviceActivityStatus.lastWeek.localizedString == Localizations.pastFourteenDays)
        #expect(DeviceActivityStatus.thisMonth.localizedString == Localizations.pastThirtyDays)
        #expect(DeviceActivityStatus.overThirtyDaysAgo.localizedString == Localizations.overThirtyDaysAgo)
        #expect(DeviceActivityStatus.unknown.localizedString == Localizations.unknown)
    }
}
