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
private final class CipherChangeSubscription<SubscriberType>: NSObject, Subscription
    where SubscriberType: Subscriber,
    SubscriberType.Input == CipherChange,
    SubscriberType.Failure == Error {
    // MARK: Properties

    /// The subscriber to notify of cipher changes.
    private var subscriber: SubscriberType?

    /// The cancellable for the notification observation.
    private var cancellable: AnyCancellable?

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
        // Unlimited demand - we emit all changes
    }

    // MARK: Cancellable

    func cancel() {
        cancellable?.cancel()
        cancellable = nil
        subscriber = nil
    }

    // MARK: Private Methods

    /// Handles Core Data context save notifications and emits cipher changes.
    ///
    /// - Parameter notification: The notification containing the saved changes.
    ///
    private func handleContextSave(_ notification: Notification) {
        guard let subscriber,
              let userInfo = notification.userInfo else {
            return
        }

        do {
            // Check inserted objects
            if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> {
                for object in inserts where object is CipherData {
                    guard let cipherData = object as? CipherData,
                          cipherData.userId == userId else {
                        continue
                    }
                    _ = subscriber.receive(.inserted(try Cipher(cipherData: cipherData)))
                }
            }

            // Check updated objects
            if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                for object in updates where object is CipherData {
                    guard let cipherData = object as? CipherData,
                          cipherData.userId == userId else {
                        continue
                    }
                    _ = subscriber.receive(.updated(try Cipher(cipherData: cipherData)))
                }
            }

            // Check deleted objects
            if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> {
                for object in deletes where object is CipherData {
                    guard let cipherData = object as? CipherData,
                          cipherData.userId == userId else {
                        continue
                    }
                    _ = subscriber.receive(.deleted(try Cipher(cipherData: cipherData)))
                }
            }
        } catch {
            subscriber.receive(completion: .failure(error))
        }
    }
}
