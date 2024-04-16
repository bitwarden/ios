import BitwardenSdk

extension TrustDeviceResponse {
    static func fixture(
        deviceKey: String = "DEVICE_KEY",
        protectedUserKey: AsymmetricEncString = "PROTECTED_USER_KEY",
        protectedDevicePrivateKey: EncString = "PRIVATE_KEY",
        protectedDevicePublicKey: EncString = "PUBLIC_KEY"
    ) -> TrustDeviceResponse {
        TrustDeviceResponse(
            deviceKey: deviceKey,
            protectedUserKey: protectedUserKey,
            protectedDevicePrivateKey: protectedDevicePrivateKey,
            protectedDevicePublicKey: protectedDevicePublicKey
        )
    }
}
