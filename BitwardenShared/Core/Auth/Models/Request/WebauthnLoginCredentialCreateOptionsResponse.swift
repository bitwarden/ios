export class WebauthnLoginCredentialCreateOptionsResponse extends BaseResponse {
  /** Options to be provided to the webauthn authenticator */
  options: ChallengeResponse;

  /**
   * Contains an encrypted version of the {@link options}.
   * Used by the server to validate the attestation response of newly created credentials.
   */
  token: string;

  constructor(response: unknown) {
    super(response);
    this.options = new ChallengeResponse(this.getResponseProperty("options"));
    this.token = this.getResponseProperty("token");
  }
}