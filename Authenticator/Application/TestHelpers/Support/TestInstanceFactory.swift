import Foundation

enum TestInstanceFactory {
    static func create<T: NSObject>(_ type: T.Type, properties: [String: Any] = [:]) -> T {
        let instance = type.init()
        for property in properties {
            instance.setValue(property.value, forKey: property.key)
        }
        return instance
    }
}
