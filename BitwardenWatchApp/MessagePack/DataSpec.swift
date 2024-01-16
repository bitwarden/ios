import Foundation

public struct DataSpec {
    let name: String
    let isObj: Bool
    let isArray: Bool
    let dataSpecBuilder: DataSpecBuilder?

    init(_ name: String, _ isObj: Bool, _ isArray: Bool, _ dataSpecBuilder: DataSpecBuilder?) {
        self.name = name
        self.isObj = isObj
        self.isArray = isArray
        self.dataSpecBuilder = dataSpecBuilder
    }
}

public class DataSpecBuilder: NSCopying {
    var specs: [DataSpec] = []
    var specsIterator: IndexingIterator<[DataSpec]>

    init() {
        specsIterator = IndexingIterator(_elements: [])
    }

    func append(_ name: String) -> DataSpecBuilder {
        append(DataSpec(name, false, false, nil))
    }

    func appendObj(_ name: String, _ dataSpecBuilder: DataSpecBuilder) -> DataSpecBuilder {
        append(DataSpec(name, true, false, dataSpecBuilder))
    }

    func appendArray(_ name: String) -> DataSpecBuilder {
        append(DataSpec(name, false, true, nil))
    }

    func appendArray(_ name: String, _ dataSpecBuilder: DataSpecBuilder) -> DataSpecBuilder {
        append(DataSpec(name, false, true, dataSpecBuilder))
    }

    func append(_ spec: DataSpec) -> DataSpecBuilder {
        specs.append(spec)
        return self
    }

    func build() -> DataSpecBuilder {
        specsIterator = specs.makeIterator()
        return self
    }

    func next() -> DataSpec {
        specsIterator.next()!
    }

    public func copy(with _: NSZone? = nil) -> Any {
        let b = DataSpecBuilder()
        b.specs = specs
        return b.build()
    }
}
