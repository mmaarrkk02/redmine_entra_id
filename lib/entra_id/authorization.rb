require_relative 'graph/jwt_builder'

class EntraId::Authorization
  attr_reader :code_verifier, :state, :nonce, :redirect_uri

  def initialize(redirect_uri:, code_verifier: nil, state: nil, nonce: nil)
    @redirect_uri = redirect_uri

    @code_verifier = code_verifier || SecureRandom.urlsafe_base64(64)
    @state = state || SecureRandom.hex(16)
    @nonce = nonce || SecureRandom.hex(16)
  end

  def code_challenge
    Base64.urlsafe_encode64 Digest::SHA256.digest(code_verifier), padding: false
  end

  def url
    client.auth_code.authorize_url(
      redirect_uri: redirect_uri,
      scope: EntraId::OAUTH_SCOPE,
      response_mode: "query",
      state: state,
      nonce: nonce,
      code_challenge: code_challenge,
      code_challenge_method: EntraId::OAUTH_CHALLENGE_METHOD,
      prompt: "select_account"
    )
  end

  def exchange_code_for_identity(code:)
    access_token = exchange_code_for_access_token(code)
    claims = decode_id_token(access_token.params["id_token"])

    if ActiveSupport::SecurityUtils.secure_compare(claims["nonce"], nonce)
      EntraId::Identity.new claims: claims, access_token: access_token.token
    else
      Rails.logger.error "Invalid nonce detected"

      nil
    end
  rescue JWT::VerificationError => e
    Rails.logger.error "EntraId token validation error (#{e.message})"

    nil
  end

  private

    def client
      @client ||= OAuth2::Client.new(
        EntraId.client_id,
        EntraId.client_secret || 'placeholder',
        site: EntraId.oauth_base_url,
        authorize_url: EntraId.authorize_path,
        token_url: EntraId.token_endpoint_path,
        auth_scheme: EntraId::Graph::AccessToken.using_certificate? ? :not_applicable : :request_body
      )
    end

    def exchange_code_for_access_token(code)
      Rails.logger.info "=== Token Exchange Start ==="
      Rails.logger.info "Auth Method: #{EntraId.auth_method}"
      Rails.logger.info "Using Certificate: #{EntraId::Graph::AccessToken.using_certificate?}"

      token_params = {
        redirect_uri: redirect_uri,
        code_verifier: code_verifier,
        grant_type: 'authorization_code',
        code: code
      }

      # Add client authentication based on auth method
      if EntraId::Graph::AccessToken.using_certificate?
        Rails.logger.info "Generating JWT for certificate auth..."
        jwt = EntraId::Graph::JwtBuilder.generate(
          EntraId.certificate_path,
          EntraId.client_id,
          EntraId.tenant_id,
          EntraId.certificate_password
        )
        Rails.logger.info "JWT Length: #{jwt.length}"
        payload, header = JWT.decode(jwt, nil, false)
        Rails.logger.info "JWT Header: #{header.inspect}"
        Rails.logger.info "JWT Payload: #{payload.inspect}"
        Rails.logger.info "JWT Full Token: #{jwt[0..100]}...#{jwt[-50..-1]}"
        Rails.logger.info "JWT Kid (Thumbprint): #{header['kid']}" rescue nil

        token_params[:client_assertion_type] = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        token_params[:client_assertion] = jwt
        token_params[:client_id] = EntraId.client_id
        Rails.logger.info "Token Params: grant_type=#{token_params[:grant_type]}, client_assertion_type=#{token_params[:client_assertion_type]}, client_id=#{token_params[:client_id]}"
      else
        Rails.logger.info "Using client secret auth"
      end

      Rails.logger.info "Sending token request to: #{EntraId.token_endpoint_path}"
      response = client.request(:post, EntraId.token_endpoint_path, body: token_params, authenticated: false)
      Rails.logger.info "=== Token Exchange Success ==="
      OAuth2::AccessToken.from_hash(client, response.parsed)
    rescue StandardError => e
      Rails.logger.error "=== Token Exchange Error ==="
      Rails.logger.error "Error: #{e.message}"
      raise
    end

    def decode_id_token(id_token)
      data, _header = JWT.decode(
        id_token, nil, true,
        {
          algorithms: [ "RS256" ],
          jwks: KeySetLoader.new,
          verify_aud: true,
          aud: EntraId.client_id,
          verify_iss: true,
          iss: EntraId.issuer_url,
          verify_iat: true
        }
      )

      data
    end
end
