require_relative 'jwt_builder'

class EntraId::Graph::AccessToken
  HOST = "login.microsoftonline.com"
  GRANT_TYPE = "client_credentials"
  GRANT_TYPE_JWT = "urn:ietf:params:oauth:grant-type:jwt-bearer"
  SCOPE = "https://graph.microsoft.com/.default"

  EXPIRATION_BUFFER = 30.seconds

  include Singleton

  class << self
    def uri
      URI::HTTPS.build host: HOST, path: path
    end

    def path
      "/#{EntraId.tenant_id}/oauth2/v2.0/token"
    end

    def using_certificate?
      EntraId.auth_method == 'certificate' && EntraId.certificate_path.present?
    end

    def token_params
      if using_certificate?
        certificate_token_params
      else
        secret_token_params
      end
    end

    def secret_token_params
      URI.encode_www_form({
        "grant_type" => GRANT_TYPE,
        "client_id" => EntraId.client_id,
        "client_secret" => EntraId.client_secret,
        "scope" => SCOPE
      })
    end

    def certificate_token_params
      jwt = EntraId::Graph::JwtBuilder.generate(
        EntraId.certificate_path,
        EntraId.client_id,
        EntraId.tenant_id,
        EntraId.certificate_password
      )

      URI.encode_www_form({
        "grant_type" => GRANT_TYPE_JWT,
        "client_id" => EntraId.client_id,
        "assertion" => jwt,
        "scope" => SCOPE
      })
    end

    def request
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Post.new(uri.path)

        request["Content-Type"] = "application/x-www-form-urlencoded"
        request.body = token_params

        http.request(request).body
      end
    end
  end

  def value(force_refresh: false)
    refresh! if force_refresh || expired?

    @current_token
  end

  private

    def refresh!
      data = JSON.parse(EntraId::Graph::AccessToken.request)

      @current_token = data["access_token"]
      @expires_at = data["expires_in"].seconds.from_now

      @current_token
    rescue StandardError => e
      Rails.logger.error "EntraId network error: #{e.message}"
      raise EntraId::NetworkError, "Network error: #{e.message}"
    end

    def expired?
      @expires_at.blank? || @expires_at <= (Time.current + EXPIRATION_BUFFER)
    end
end
