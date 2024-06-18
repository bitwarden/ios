import Foundation

// MARK: - EventService

/// A protocol for a service that manages organization events. This includes saving events to disk
/// and uploading those events.
///
protocol EventService {
    /// Save an event to disk for future upload.
    ///
    /// - Parameters:
    ///   - eventType: The event to track.
    ///   - cipherId: The ID of the relevant cipher for some events.
    ///   - uploadImmediately: If `true` then immediately attempts an upload after saving.
    func collect(eventType: EventType, cipherId: String?, uploadImmediately: Bool) async throws
}

extension EventService {
    func collect(
        eventType: EventType,
        cipherId: String? = nil,
        uploadImmediately: Bool = false
    ) async throws {
        try await collect(eventType: eventType, cipherId: cipherId, uploadImmediately: uploadImmediately)
    }
}

// MARK: - DefaultEventService

/// The default implementation of an `EventService`.
///
class DefaultEventService: EventService {
    // MARK: Properties

    /// The service used to manage ciphers.
    let cipherService: CipherService

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
    ///   - organizationService: The service used to manage organizations.
    ///   - stateService: The service used to manage account state.
    ///   - timeProvider: The service used to provide time.
    ///
    init(
        cipherService: CipherService,
        organizationService: OrganizationService,
        stateService: StateService,
        timeProvider: TimeProvider
    ) {
        self.cipherService = cipherService
        self.organizationService = organizationService
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    // MARK: Methods

    func collect(eventType: EventType, cipherId: String?, uploadImmediately: Bool) async throws {
        guard await stateService.isAuthenticated() else { return }

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

        let newEvent = EventData(
            type: eventType,
            cipherId: cipherId,
            date: timeProvider.presentTime
        )

        try await stateService.setEvents([newEvent], userId: "1")
    }
}
