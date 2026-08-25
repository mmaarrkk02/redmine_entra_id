module EntraId::MaskableSettings
  extend ActiveSupport::Concern

  included do
    before_action :prepare_entra_id_settings, only: [ :plugin ]
  end

  private

    def prepare_entra_id_settings
      return unless params[:id] == "entra_id"
      return unless request.post?

      # Client secret should be set via environment variable ENTRA_ID_CLIENT_SECRET
      # Remove from settings to prevent accidental modification via UI
      params[:settings].delete(:client_secret)

      # Handle certificate password - don't save empty passwords
      received_cert_password = params.dig(:settings, :certificate_password)
      if received_cert_password.blank?
        # Remove from params if empty to avoid overwriting existing value
        params[:settings].delete(:certificate_password)
      elsif received_cert_password.present?
        # Certificate password should ideally be set via environment variable
        # But allow UI configuration as fallback
        params[:settings][:certificate_password] = received_cert_password
      end

      # Ensure certificate path is not empty if auth method is certificate
      auth_method = params.dig(:settings, :auth_method)
      if auth_method == 'certificate'
        cert_path = params.dig(:settings, :certificate_path)
        if cert_path.blank? && !ENV["ENTRA_ID_CERTIFICATE_PATH"].present?
          flash[:error] = l(:error_entra_id_certificate_path_required)
          params[:settings][:auth_method] = 'secret'  # Revert to default
        end
      end
    end
end
