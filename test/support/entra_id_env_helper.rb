# frozen_string_literal: true

module EntraIdEnvHelper
  extend ActiveSupport::Concern

  included do
    setup :setup_entra_id_env
    teardown :teardown_entra_id_env
  end

  def setup_entra_id_env
    ENV["ENTRA_ID_CLIENT_ID"] = "test-client-id"
    ENV["ENTRA_ID_CLIENT_SECRET"] = "test-secret-123"
    ENV["ENTRA_ID_TENANT_ID"] = "test-tenant-id"
    ENV["ENTRA_ID_AUTH_METHOD"] = "secret"
  end

  def teardown_entra_id_env
    ENV.delete("ENTRA_ID_CLIENT_ID")
    ENV.delete("ENTRA_ID_CLIENT_SECRET")
    ENV.delete("ENTRA_ID_TENANT_ID")
    ENV.delete("ENTRA_ID_AUTH_METHOD")
    ENV.delete("ENTRA_ID_CERTIFICATE_PATH")
    ENV.delete("ENTRA_ID_CERTIFICATE_PASSWORD")
  end

  def setup_certificate_env(cert_path = nil, password = nil)
    ENV["ENTRA_ID_AUTH_METHOD"] = "certificate"
    ENV["ENTRA_ID_CERTIFICATE_PATH"] = cert_path || "test-cert.pem"
    ENV["ENTRA_ID_CERTIFICATE_PASSWORD"] = password if password.present?
  end

  def teardown_certificate_env
    setup_entra_id_env  # Reset to default secret auth
  end
end