import Combine

public extension MockServerCommunicationConfigAPIService {
    /// Creates a `MockServerCommunicationConfigAPIService` pre-configured with a non-nil
    /// cookie-acquisition publisher.
    ///
    static func withDefaults() -> MockServerCommunicationConfigAPIService {
        let service = MockServerCommunicationConfigAPIService()
        service.acquireCookiesPublisherReturnValue = CurrentValueSubject<String?, Never>(nil).eraseToAnyPublisher()
        return service
    }
}
