import BitwardenKit
import Foundation

// MARK: - EventService

/// A protocol for a service that manages organization events. This includes saving events to disk
/// and uploading those events.
///
protocol EventService {
    /// Save an event to disk for future upload. This does not propagate errors that might be
    /// thrown in internal processing to avoid complexity at call sites, and instead just
    /// logs the error.
    ///
    /// - Parameters:
    ///   - eventType: The event to track.
    ///   - cipherId: The ID of the relevant cipher for some events.
    func collect(eventType: EventType, cipherId: String?) async

    /// Uploads events saved to disk. This does not propagate errors that might be
    /// thrown and instead just logs the error.
    func upload() async
}

extension EventService {
    func collect(
        eventType: EventType,
        cipherId: String? = nil
    ) async {
        await collect(eventType: eventType, cipherId: cipherId)
    }
}

// MARK: - DefaultEventService

/// The default implementation of an `EventService`.
///
class DefaultEventService: EventService {
    // MARK: Properties

    /// The service used to manage ciphers.
    let cipherService: CipherService

    /// The service used to report errors.
    let errorReporter: ErrorReporter

    /// The service to send events to the backend.
    let eventAPIService: EventAPIService

    /// The service used to manage organizations.
    let organizationService: OrganizationService

    /// The service used to manage account state.
    let stateService: StateService

    /// The service used to provide time.
    let timeProvider: TimeProvider

    // MARK: Initialization

    /// Initialize a `DefaultEventService`.
    ///
    /// - Parameters:
    ///   - cipherService: The service used to manage ciphers.
    ///   - errorReporter: The service used to report errors.
    ///   - eventAPIService: The service to send events to the backend.
    ///   - organizationService: The service used to manage organizations.
    ///   - stateService: The service used to manage account state.
    ///   - timeProvider: The service used to provide time.
    ///
    init(
        cipherService: CipherService,
        errorReporter: ErrorReporter,
        eventAPIService: EventAPIService,
        organizationService: OrganizationService,
        stateService: StateService,
        timeProvider: TimeProvider
    ) {
        self.cipherService = cipherService
        self.errorReporter = errorReporter
        self.eventAPIService = eventAPIService
        self.organizationService = organizationService
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    // MARK: Methods

    func collect(eventType: EventType, cipherId: String?) async {
        do {
            guard let userId = try? await stateService.getActiveAccountId() else { return }

            let organizations = try await organizationService.fetchAllOrganizations().filter(\.useEvents)

            guard !organizations.isEmpty else {
                return
            }

            if let cipherId {
                guard let cipher = try await cipherService.fetchCipher(withId: cipherId),
                      let orgId = cipher.organizationId,
                      organizations.map(\.id).contains(orgId) else {
                    return
                }
            }

            var events = try await stateService.getEvents(userId: userId)

            let newEvent = EventData(
                type: eventType,
                cipherId: cipherId,
                date: timeProvider.presentTime
            )

            events.append(newEvent)

            try await stateService.setEvents(events, userId: userId)
        } catch {
            errorReporter.log(error: error)
        }
    }

    func upload() async {
        do {
            guard let userId = try? await stateService.getActiveAccountId() else { return }

            let events = try await stateService.getEvents(userId: userId)
            guard !events.isEmpty else { return }

            try await eventAPIService.postEvents(events)

            try await stateService.setEvents([], userId: userId)
        } catch {
            errorReporter.log(error: error)
        }
    }
}
