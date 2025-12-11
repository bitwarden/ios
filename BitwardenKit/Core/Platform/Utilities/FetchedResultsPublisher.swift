import Combine
import CoreData

// MARK: - FetchedResultsPublisher

/// A Combine publisher that publishes the initial result set and any future data changes for a
/// Core Data fetch request.
///
/// Adapted from https://gist.github.com/darrarski/28d2f5a28ef2c5669d199069c30d3d52
///
public class FetchedResultsPublisher<ResultType, Output>: Publisher where ResultType: NSFetchRequestResult {
    // MARK: Types

    public typealias Failure = Error

    // MARK: Properties

    /// The managed object context that the fetch request is executed against.
    let context: NSManagedObjectContext

    /// The fetch request used to get the objects.
    let request: NSFetchRequest<ResultType>

    /// A transformation closure that converts the fetched Core Data objects to the desired output type.
    /// This transformation is executed on the managed object context's queue, ensuring thread-safe
    /// access to Core Data objects.
    let transform: ([ResultType]) throws -> Output

    // MARK: Initialization

    /// Initialize a `FetchedResultsPublisher` with a transformation closure.
    ///
    /// - Parameters:
    ///   - context: The managed object context that the fetch request is executed against.
    ///   - request: The fetch request used to get the objects.
    ///   - transform: A transformation closure that converts fetched Core Data objects
    ///     to the desired output type. This closure is executed on the context's queue to ensure
    ///     thread safety.
    ///
    public init(
        context: NSManagedObjectContext,
        request: NSFetchRequest<ResultType>,
        transform: @escaping ([ResultType]) throws -> Output,
    ) {
        self.context = context
        self.request = request
        self.transform = transform
    }

    /// Initialize a `FetchedResultsPublisher` that publishes fetched objects directly without transformation.
    ///
    /// - Parameters:
    ///   - context: The managed object context that the fetch request is executed against.
    ///   - request: The fetch request used to get the objects.
    ///
    public convenience init(
        context: NSManagedObjectContext,
        request: NSFetchRequest<ResultType>,
    ) where Output == [ResultType] {
        self.init(
            context: context,
            request: request,
            transform: { $0 },
        )
    }

    // MARK: Publisher

    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
        subscriber.receive(subscription: FetchedResultsSubscription(
            context: context,
            request: request,
            transform: transform,
            subscriber: subscriber,
        ))
    }
}

// MARK: - FetchedResultsSubscription

/// A `Subscription` to a `FetchedResultsPublisher` which fetches results from Core Data via a
/// `NSFetchedResultsController` and notifies the subscriber of any changes to the data.
///
private final class FetchedResultsSubscription<SubscriberType, ResultType, Output>: NSObject, Subscription,
    NSFetchedResultsControllerDelegate
    where SubscriberType: Subscriber,
    SubscriberType.Input == Output,
    SubscriberType.Failure == Error,
    ResultType: NSFetchRequestResult {
    // MARK: Properties

    /// The fetched results controller to manage the results of a Core Data fetch request.
    private var controller: NSFetchedResultsController<ResultType>?

    /// The current demand from the subscriber.
    private var demand: Subscribers.Demand = .none

    /// Whether the subscription has changes to send to the subscriber.
    private var hasChangesToSend = false

    /// A serial queue to synchronize access to subscription state.
    private let queue = DispatchQueue(label: "com.bitwarden.FetchedResultsSubscription")

    /// The subscriber to the subscription that is notified of the fetched results.
    private var subscriber: SubscriberType?

    /// A transformation closure that converts the fetched Core Data objects to the desired output type.
    private let transform: ([ResultType]) throws -> Output

    // MARK: Initialization

    /// Initialize a `FetchedResultsSubscription`.
    ///
    /// - Parameters:
    ///   - context: The managed object context that the fetch request is executed against.
    ///   - request: The fetch request used to get the objects.
    ///   - transform: A transformation closure that converts fetched Core Data objects
    ///     to the desired output type.
    ///   - subscriber: The subscriber to the subscription that is notified of the fetched results.
    ///
    init(
        context: NSManagedObjectContext,
        request: NSFetchRequest<ResultType>,
        transform: @escaping ([ResultType]) throws -> Output,
        subscriber: SubscriberType,
    ) {
        controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil,
        )
        self.transform = transform
        self.subscriber = subscriber

        super.init()

        controller?.delegate = self

        queue.async {
            do {
                try self.controller?.performFetch()
                if self.controller?.fetchedObjects != nil {
                    self.hasChangesToSend = true
                    self.fulfillDemand()
                }
            } catch {
                subscriber.receive(completion: .failure(error))
            }
        }
    }

    // MARK: Subscription

    func request(_ demand: Subscribers.Demand) {
        queue.async {
            self.demand += demand
            self.fulfillDemand()
        }
    }

    // MARK: Cancellable

    func cancel() {
        queue.async {
            self.controller = nil
            self.subscriber = nil
        }
    }

    // MARK: NSFetchedResultsControllerDelegate

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        queue.async {
            self.hasChangesToSend = true
            self.fulfillDemand()
        }
    }

    // MARK: Private

    private func fulfillDemand() {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(queue))
        #endif

        guard demand > 0,
              hasChangesToSend,
              let subscriber
        else { return }

        hasChangesToSend = false
        demand -= 1

        controller?.managedObjectContext.perform { [weak self] in
            guard let self,
                  let fetchedObjects = controller?.fetchedObjects
            else { return }

            do {
                let output = try transform(fetchedObjects)
                queue.async {
                    self.demand += subscriber.receive(output)
                }
            } catch {
                queue.async {
                    subscriber.receive(completion: .failure(error))
                }
            }
        }
    }
}
