import Combine
import CoreData

// MARK: - FetchedResultsPublisher

/// A Combine publisher that publishes the initial result set and any future data changes for a
/// Core Data fetch request.
///
/// Adapted from https://gist.github.com/darrarski/28d2f5a28ef2c5669d199069c30d3d52
///
class FetchedResultsPublisher<ResultType>: Publisher where ResultType: NSFetchRequestResult {
    // MARK: Types

    typealias Output = [ResultType]

    typealias Failure = Error

    // MARK: Properties

    /// The managed object context that the fetch request is executed against.
    let context: NSManagedObjectContext

    /// The fetch request used to get the objects.
    let request: NSFetchRequest<ResultType>

    // MARK: Initialization

    /// Initialize a `FetchedResultsPublisher`.
    ///
    /// - Parameters:
    ///   - context: The managed object context that the fetch request is executed against.
    ///   - request: The fetch request used to get the objects.
    ///
    init(context: NSManagedObjectContext, request: NSFetchRequest<ResultType>) {
        self.context = context
        self.request = request
    }

    // MARK: Publisher

    func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
        subscriber.receive(subscription: FetchedResultsSubscription(
            context: context,
            request: request,
            subscriber: subscriber
        ))
    }
}

// MARK: - FetchedResultsSubscription

/// A `Subscription` to a `FetchedResultsPublisher` which fetches results from Core Data via a
/// `NSFetchedResultsController` and notifies the subscriber of any changes to the data.
///
private final class FetchedResultsSubscription<SubscriberType, ResultType>: NSObject, Subscription,
    NSFetchedResultsControllerDelegate
    where SubscriberType: Subscriber,
    SubscriberType.Input == [ResultType],
    SubscriberType.Failure == Error,
    ResultType: NSFetchRequestResult {
    // MARK: Properties

    /// The fetched results controller to manage the results of a Core Data fetch request.
    private var controller: NSFetchedResultsController<ResultType>?

    /// The current demand from the subscriber.
    private var demand: Subscribers.Demand = .none

    /// Whether the subscription has changes to send to the subscriber.
    private var hasChangesToSend = false

    /// The subscriber to the subscription that is notified of the fetched results.
    private var subscriber: SubscriberType?

    // MARK: Initialization

    /// Initialize a `FetchedResultsSubscription`.
    ///
    /// - Parameters:
    ///   - context: The managed object context that the fetch request is executed against.
    ///   - request: The fetch request used to get the objects.
    ///   - subscriber: The subscriber to the subscription that is notified of the fetched results.
    ///
    init(
        context: NSManagedObjectContext,
        request: NSFetchRequest<ResultType>,
        subscriber: SubscriberType
    ) {
        controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.subscriber = subscriber

        super.init()

        controller?.delegate = self

        do {
            try controller?.performFetch()
            if controller?.fetchedObjects != nil {
                hasChangesToSend = true
                fulfillDemand()
            }
        } catch {
            subscriber.receive(completion: .failure(error))
        }
    }

    // MARK: Subscription

    func request(_ demand: Subscribers.Demand) {
        self.demand += demand
        fulfillDemand()
    }

    // MARK: Cancellable

    func cancel() {
        controller = nil
        subscriber = nil
    }

    // MARK: NSFetchedResultsControllerDelegate

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        hasChangesToSend = true
        fulfillDemand()
    }

    // MARK: Private

    private func fulfillDemand() {
        guard demand > 0, hasChangesToSend,
              let subscriber,
              let fetchedObjects = controller?.fetchedObjects
        else { return }

        hasChangesToSend = false
        demand -= 1
        demand += subscriber.receive(fetchedObjects)
    }
}
