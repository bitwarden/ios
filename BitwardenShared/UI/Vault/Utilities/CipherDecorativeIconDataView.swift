import BitwardenSdk

/// A protocol to get data used for decorative icons.
protocol CipherDecorativeIconDataView {
    /// The login uris to get the icon.
    var uris: [LoginUriView]? { get }
}
