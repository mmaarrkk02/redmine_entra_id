require File.expand_path('../../../test_helper', __FILE__)

class EntraId::CertificateAuthTest < Redmine::IntegrationTest
  def setup
    @client_id = '12345678-1234-1234-1234-123456789012'
    @tenant_id = '87654321-4321-4321-4321-210987654321'
  end

  test "should select certificate authentication method" do
    log_user('admin', 'admin')

    get '/settings/plugin/entra_id'
    assert_response :success

    # Fill in required fields
    post '/settings/plugin/entra_id',
      params: {
        settings: {
          enabled: true,
          auth_method: 'certificate',
          client_id: @client_id,
          tenant_id: @tenant_id,
          certificate_path: '/path/to/cert.pem'
        }
      }

    # Verify settings were saved
    assert_equal 'certificate', Setting.plugin_entra_id[:auth_method]
    assert_equal '/path/to/cert.pem', Setting.plugin_entra_id[:certificate_path]
  end

  test "should validate required fields for certificate auth" do
    with_settings 'entra_id' => {
      enabled: true,
      auth_method: 'certificate',
      client_id: '',
      tenant_id: @tenant_id,
      certificate_path: '/path/to/cert.pem'
    } do
      refute EntraId.valid?, "Should be invalid without client_id"
    end
  end

  test "should return false for auth when certificate file does not exist" do
    with_settings 'entra_id' => {
      enabled: true,
      auth_method: 'certificate',
      client_id: @client_id,
      tenant_id: @tenant_id,
      certificate_path: '/nonexistent/cert.pem'
    } do
      # Mock the environment to use settings
      EntraId.stub(:certificate_path, '/nonexistent/cert.pem') do
        refute EntraId.valid?, "Should be invalid when certificate doesn't exist"
      end
    end
  end

  test "should validate client secret auth method" do
    with_settings 'entra_id' => {
      enabled: true,
      auth_method: 'secret',
      client_id: @client_id,
      tenant_id: @tenant_id
    } do
      # This would be valid if client_secret is in environment
      # but in test env it won't be set
      EntraId.stub(:client_secret, 'test-secret') do
        assert EntraId.valid?
      end
    end
  end

  private

    def with_settings(plugin_name, settings)
      old_settings = Setting.plugin_entra_id.dup
      Setting.plugin_entra_id = settings
      yield
      Setting.plugin_entra_id = old_settings
    end
end
