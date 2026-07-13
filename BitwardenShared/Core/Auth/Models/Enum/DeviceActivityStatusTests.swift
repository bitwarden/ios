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

    /// `init(from:timeProvider:)` returns `.thisWeek` at the 7-day boundary.
    @Test
    func init_thisWeek_upperBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -7, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .thisWeek)
    }

    /// `init(from:timeProvider:)` returns `.lastWeek` at the 8-day boundary.
    @Test
    func init_lastWeek_lowerBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -8, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .lastWeek)
    }

    /// `init(from:timeProvider:)` returns `.lastWeek` at the 14-day boundary.
    @Test
    func init_lastWeek_upperBound() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -14, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .lastWeek)
    }

    /// `init(from:timeProvider:)` returns `.thisMonth` when the date is more than two weeks ago
    /// but still falls within the current calendar month.
    @Test
    func init_thisMonth_sameCalendarMonth() throws {
        let present = try #require(DateComponents(calendar: .current, year: 2024, month: 6, day: 30).date)
        let date = try #require(DateComponents(calendar: .current, year: 2024, month: 6, day: 15).date)
        let provider = MockTimeProvider(.mockTime(present))
        #expect(DeviceActivityStatus(from: date, timeProvider: provider) == .thisMonth)
    }

    /// `init(from:timeProvider:)` returns `.overThirtyDaysAgo`, not `.thisMonth`, when the date is
    /// more than two weeks ago and falls in a previous calendar month, even if fewer than 30 days
    /// have elapsed.
    @Test
    func init_notThisMonth_previousCalendarMonth() throws {
        let present = try #require(DateComponents(calendar: .current, year: 2024, month: 7, day: 15).date)
        let date = try #require(DateComponents(calendar: .current, year: 2024, month: 6, day: 20).date)
        let provider = MockTimeProvider(.mockTime(present))
        #expect(DeviceActivityStatus(from: date, timeProvider: provider) == .overThirtyDaysAgo)
    }

    /// `init(from:timeProvider:)` returns `.overThirtyDaysAgo` when the date is 31 days ago.
    @Test
    func init_overThirtyDays() throws {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -31, to: timeProvider.presentTime))
        #expect(DeviceActivityStatus(from: date, timeProvider: timeProvider) == .overThirtyDaysAgo)
    }

    /// `localizedString` returns the correct value for each status.
    @Test
    func localizedString() {
        #expect(DeviceActivityStatus.today.localizedString == Localizations.today)
        #expect(DeviceActivityStatus.thisWeek.localizedString == Localizations.thisWeek)
        #expect(DeviceActivityStatus.lastWeek.localizedString == Localizations.lastWeek)
        #expect(DeviceActivityStatus.thisMonth.localizedString == Localizations.thisMonth)
        #expect(DeviceActivityStatus.overThirtyDaysAgo.localizedString == Localizations.overThirtyDaysAgo)
        #expect(DeviceActivityStatus.unknown.localizedString == Localizations.unknown)
    }
}
