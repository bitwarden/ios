import BitwardenSdk
import Combine
import CoreData

// MARK: - CipherChange

/// Represents a change to a cipher in the data store.
///
public enum CipherChange {
    /// A cipher was inserted.
    case inserted(Cipher)

    /// A cipher was updated.
    case updated(Cipher)

    /// A cipher was deleted.
    case deleted(Cipher)
}

// MARK: - CipherChangePublisher

/// A Combine publisher that publishes individual cipher changes (insert, update, delete) as they occur.
///
/// This publisher monitors Core Data's `NSManagedObjectContextDidSave` notifications and emits
/// changes for individual cipher operations. Batch operations like `replaceCiphers` do not trigger
/// these notifications and therefore won't emit changes.
///
public class CipherChangePublisher: Publisher {
    // MARK: Types

    public typealias Output = CipherChange

    public typealias Failure = Error

    // MARK: Properties

    /// The managed object context to observe for cipher changes.
    let context: NSManagedObjectContext

    /// The user ID to filter cipher changes.
    let userId: String

    // MARK: Initialization

    /// Initialize a `CipherChangePublisher`.
    ///
    /// - Parameters:
    ///   - context: The managed object context to observe for cipher changes.
    ///   - userId: The user ID to filter cipher changes.
    ///
    public init(context: NSManagedObjectContext, userId: String) {
        self.context = context
        self.userId = userId
    }

    // MARK: Publisher

    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
        subscriber.receive(subscription: CipherChangeSubscription(
            context: context,
            userId: userId,
            subscriber: subscriber,
        ))
    }
}

// MARK: - CipherChangeSubscription

/// A `Subscription` to a `CipherChangePublisher` which observes Core Data save notifications
/// and notifies the subscriber of individual cipher changes.
///
/// This subscription respects Combine's backpressure system by buffering changes when the subscriber's
/// demand is exhausted, ensuring no cipher changes are lost.
///
private final class CipherChangeSubscription<SubscriberType>: NSObject, Subscription
    where SubscriberType: Subscriber,
    SubscriberType.Input == CipherChange,
    SubscriberType.Failure == Error {
    // MARK: Properties

    /// Buffer for changes that arrive when demand is exhausted. Queue-confined.
    private var buffer: [CipherChange] = []

    /// The cancellable for the notification observation.
    private var cancellable: AnyCancellable?

    /// Tracks the current demand from the subscriber. Queue-confined.
    private var demand: Subscribers.Demand = .none

    /// Serial queue for synchronizing all state access.
    private let queue = DispatchQueue(label: "com.bitwarden.CipherChangeSubscription")

    /// The subscriber to notify of cipher changes.
    private var subscriber: SubscriberType?

    /// The user ID to filter cipher changes.
    private let userId: String

    // MARK: Initialization

    /// Initialize a `CipherChangeSubscription`.
    ///
    /// - Parameters:
    ///   - context: The managed object context to observe for cipher changes.
    ///   - userId: The user ID to filter cipher changes.
    ///   - subscriber: The subscriber to notify of cipher changes.
    ///
    init(
        context: NSManagedObjectContext,
        userId: String,
        subscriber: SubscriberType,
    ) {
        self.userId = userId
        self.subscriber = subscriber
        super.init()

        cancellable = NotificationCenter.default.publisher(
            for: .NSManagedObjectContextDidSave,
            object: context,
        )
        .sink { [weak self] notification in
            self?.handleContextSave(notification)
        }
    }

    // MARK: Subscription

    func request(_ demand: Subscribers.Demand) {
        queue.async { [weak self] in
            guard let self else { return }
            self.demand += demand
            fulfillDemand()
        }
    }

    // MARK: Cancellable

    func cancel() {
        queue.async { [weak self] in
            self?.cancellable?.cancel()
            self?.cancellable = nil
            self?.subscriber = nil
        }
    }

    // MARK: Private Methods

    /// Attempts to send changes to the subscriber, queuing it if demand is exhausted.
    ///
    /// - Parameter changes: The cipher changes to send.
    ///
    private func send(_ changes: [CipherChange]) {
        queue.async { [weak self] in
            guard let self else { return }
            buffer.append(contentsOf: changes)
            fulfillDemand()
        }
    }

    /// Delivers pending changes to the subscriber based on available demand.
    ///
    private func fulfillDemand() {
        while !buffer.isEmpty, demand > .none, let subscriber {
            let change = buffer.removeFirst()
            let newDemand = subscriber.receive(change)
            demand -= 1
            demand += newDemand
        }
    }

    /// Handles Core Data context save notifications and emits cipher changes.
    ///
    /// - Parameter notification: The notification containing the saved changes.
    ///
    private func handleContextSave(_ notification: Notification) { // swiftlint:disable:this cyclomatic_complexity
        guard let userInfo = notification.userInfo else {
            return
        }

        // Collect all changes
        var changes: [CipherChange] = []

        do {
            // Check inserted objects
            if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> {
                for object in inserts where object is CipherData {
                    guard let cipherData = object as? CipherData,
                          cipherData.userId == userId else {
                        continue
                    }
                    try changes.append(.inserted(Cipher(cipherData: cipherData)))
                }
            }

            // Check updated objects
            if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                for object in updates where object is CipherData {
                    guard let cipherData = object as? CipherData,
                          cipherData.userId == userId else {
                        continue
                    }
                    try changes.append(.updated(Cipher(cipherData: cipherData)))
                }
            }

            // Check deleted objects
            if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> {
                for object in deletes where object is CipherData {
                    guard let cipherData = object as? CipherData,
                          cipherData.userId == userId else {
                        continue
                    }
                    try changes.append(.deleted(Cipher(cipherData: cipherData)))
                }
            }
        } catch {
            queue.async { [weak self] in
                self?.subscriber?.receive(completion: .failure(error))
            }
            return
        }

        if !changes.isEmpty {
            send(changes)
        }
    }
}
