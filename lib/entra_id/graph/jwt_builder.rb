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
    Rails.logger.info "=== JWT Generation Start ==="
    Rails.logger.info "Certificate Path: #{@certificate_path}"
    Rails.logger.info "Certificate Exists: #{File.exist?(@certificate_path.to_s)}"
    Rails.logger.info "Certificate Size: #{File.size(@certificate_path.to_s) if File.exist?(@certificate_path.to_s)} bytes"
    Rails.logger.info "Client ID: #{@client_id}"
    Rails.logger.info "Tenant ID: #{@tenant_id}"
    Rails.logger.info "Certificate Password Length: #{@certificate_password.to_s.length}"

    thumb = certificate_thumb
    Rails.logger.info "Certificate Thumbprint: #{thumb}"

    payload = {
      aud: token_url,
      exp: (Time.current + EXPIRES_IN).to_i,
      iss: @client_id,
      sub: @client_id,
      iat: Time.current.to_i,
      jti: SecureRandom.uuid
    }

    Rails.logger.info "JWT Payload: #{payload.inspect}"
    jwt = JWT.encode(payload, private_key, ALGORITHM, {kid: thumb})
    Rails.logger.info "JWT Generated Successfully"
    Rails.logger.info "=== JWT Generation End ==="

    jwt
  rescue StandardError => e
    Rails.logger.error "=== JWT Generation Error ==="
    Rails.logger.error "Error: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
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
      password = @certificate_password.to_s
      if password.empty?
        Rails.logger.warn "WARNING: Loading PFX without password. If PFX is password-protected, authentication will fail."
      end

      pkcs12 = OpenSSL::PKCS12.new(cert_data, password.empty? ? nil : password)
      pkcs12.key
    rescue StandardError => e
      if e.message.include?("mac verify failure")
        raise EntraId::NetworkError, "Failed to load PFX certificate: Password incorrect or PFX corrupted. Verify ENTRA_ID_CERTIFICATE_PASSWORD environment variable is set correctly. Error: #{e.message}"
      end
      raise EntraId::NetworkError, "Failed to load PFX certificate: #{e.message}"
    end

    def certificate_thumb
      @certificate_thumb ||= begin
        cert_data = File.read(@certificate_path)

        if @certificate_path.end_with?('.pfx', '.p12')
          password = @certificate_password.to_s
          pkcs12 = OpenSSL::PKCS12.new(cert_data, password.empty? ? nil : password)
          cert = pkcs12.certificate
        else
          cert = OpenSSL::X509::Certificate.new(cert_data)
        end

        Digest::SHA1.hexdigest(cert.to_der).upcase
      end
    rescue StandardError => e
      if e.message.include?("mac verify failure")
        raise EntraId::NetworkError, "Failed to load certificate thumbprint: Password incorrect or PFX corrupted. Verify ENTRA_ID_CERTIFICATE_PASSWORD is set correctly."
      end
      raise EntraId::NetworkError, "Failed to load certificate: #{e.message}"
    end

    def token_url
      "https://login.microsoftonline.com/#{@tenant_id}/oauth2/v2.0/token"
    end
end
