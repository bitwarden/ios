import CoreData

/// A protocol for an `NSManagedObject` data model that adds some convenience methods for working
/// with Core Data.
///
protocol ManagedObject: AnyObject {
    /// The name of the entity of the managed object, as defined in the data model.
    static var entityName: String { get }
}

extension ManagedObject where Self: NSManagedObject {
    static var entityName: String {
        String(describing: self)
    }

    /// Returns a `NSFetchRequest` for fetching instances of the managed object.
    ///
    /// - Returns: A `NSFetchRequest` used to fetch instances of the managed object.
    ///
    static func fetchRequest() -> NSFetchRequest<Self> {
        NSFetchRequest<Self>(entityName: entityName)
    }

    /// Returns a `NSFetchRequest` for fetching a generic `NSFetchRequestResult` instances of the
    /// managed object.
    ///
    /// - Returns: A `NSFetchRequest` used to fetch generic `NSFetchRequestResult` instances of the
    ///     managed object.
    ///
    static func fetchResultRequest() -> NSFetchRequest<NSFetchRequestResult> {
        NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
    }
}
