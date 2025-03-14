import CoreData
import OSLog

/// A protocol for a `NSManagedObject` which persists a data model as JSON encoded data. The model
/// can be set via the `model` property which encodes the model to the data property, which should
/// be a `@NSManaged` property of the `NSManagedObject`. When the managed object is populated from
/// the database, the `model` property can be read to decode the data.
///
protocol CodableModelData: AnyObject, NSManagedObject {
    associatedtype Model: Codable

    /// A `@NSManaged` property of the manage object for storing the encoded model as data.
    var modelData: Data? { get set }
}

extension CodableModelData {
    /// Encodes or decodes the model to/from the data instance.
    var model: Model? {
        get {
            guard let modelData else { return nil }
            do {
                return try JSONDecoder().decode(Model.self, from: modelData)
            } catch {
                Logger.application.error("Error decoding \(String(describing: Model.self)): \(error)")
                return nil
            }
        }
        set {
            guard let newValue else {
                modelData = nil
                return
            }
            do {
                modelData = try JSONEncoder().encode(newValue)
            } catch {
                Logger.application.error("Error encoding \(String(describing: Model.self)): \(error)")
            }
        }
    }
}
