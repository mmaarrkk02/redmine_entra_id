require 'jwt'
require 'openssl'

class EntraId::Graph::JwtBuilder
  ALGORITHM = 'RS256'
  EXPIRES_IN = 10.minutes

  class << self
    def generate(certificate_path, client_id, tenant_id, certificate_password = nil)
      new(certificate_path, client_id, tenant_id, certificate_password).build
    end
  end

  def initialize(certificate_path, client_id, tenant_id, certificate_password = nil)
    @certificate_path = certificate_path
    @client_id = client_id
    @tenant_id = tenant_id
    @certificate_password = certificate_password
  end

  def build
    payload = {
      aud: token_url,
      exp: (Time.current + EXPIRES_IN).to_i,
      iss: @client_id,
      sub: @client_id,
      iat: Time.current.to_i,
      jti: SecureRandom.uuid
    }

    JWT.encode(payload, private_key, ALGORITHM, {kid: certificate_thumb})
  rescue StandardError => e
    raise EntraId::NetworkError, "Failed to generate JWT: #{e.message}"
  end

  private

    def private_key
      @private_key ||= load_private_key
    end

    def load_private_key
      cert_data = File.read(@certificate_path)

      if @certificate_path.end_with?('.pfx', '.p12')
        load_pfx_key(cert_data)
      else
        OpenSSL::PKey::RSA.new(cert_data, @certificate_password)
      end
    rescue StandardError => e
      raise EntraId::NetworkError, "Failed to load certificate: #{e.message}"
    end

    def load_pfx_key(cert_data)
      pkcs12 = OpenSSL::PKCS12.new(cert_data, @certificate_password)
      pkcs12.key
    rescue StandardError => e
      raise EntraId::NetworkError, "Failed to load PFX certificate: #{e.message}"
    end

    def certificate_thumb
      @certificate_thumb ||= begin
        cert_data = File.read(@certificate_path)

        if @certificate_path.end_with?('.pfx', '.p12')
          pkcs12 = OpenSSL::PKCS12.new(cert_data, @certificate_password)
          cert = pkcs12.certificate
        else
          cert = OpenSSL::X509::Certificate.new(cert_data)
        end

        Digest::SHA1.hexdigest(cert.to_der).upcase
      end
    rescue StandardError => e
      raise EntraId::NetworkError, "Failed to load certificate: #{e.message}"
    end

    def token_url
      "https://login.microsoftonline.com/#{@tenant_id}/oauth2/v2.0/token"
    end
end
