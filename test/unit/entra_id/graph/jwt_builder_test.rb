require File.expand_path('../../../../test_helper', __FILE__)

class EntraId::Graph::JwtBuilderTest < ActiveSupport::TestCase
  def setup
    @client_id = 'test-client-id'
    @tenant_id = 'test-tenant-id'
    # Use a test certificate path (this would need to be a real cert for actual testing)
    @certificate_path = File.expand_path('../fixtures/test_cert.pem', __dir__)
  end

  test "should raise error if certificate file not found" do
    builder = EntraId::Graph::JwtBuilder.new('/nonexistent/cert.pem', @client_id, @tenant_id)

    assert_raises(EntraId::NetworkError) do
      builder.build
    end
  end

  test "should include required JWT claims" do
    skip "Certificate fixture not available for testing" unless ENV['TEST_WITH_REAL_CERTS']

    jwt = EntraId::Graph::JwtBuilder.generate(@certificate_path, @client_id, @tenant_id)

    # Decode without verification to check claims (verification requires public key)
    payload = JWT.decode(jwt, nil, false)[0]

    assert_equal @client_id, payload['iss']
    assert_equal @client_id, payload['sub']
    assert payload['aud'].include?(@tenant_id)
    assert payload['exp'].present?
    assert payload['iat'].present?
    assert payload['jti'].present?
  end
end
