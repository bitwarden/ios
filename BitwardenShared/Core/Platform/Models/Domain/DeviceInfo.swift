/// A model containing information about the device.
///
struct DeviceInfo {
    // MARK: Properties

    /// The device's identifier.
    let identifier: String

    /// The device's name.
    let name: String

    /// The device's type.
    let type: DeviceType = Constants.deviceType
}
