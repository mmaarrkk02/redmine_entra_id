# Certificate Authentication Support

## Overview

As of version 1.1.0, the Redmine Entra ID plugin supports certificate-based authentication using JWT (JSON Web Tokens) in addition to the traditional client secret method. This provides a more secure alternative to client passwords, which Microsoft has deprecated for many OAuth 2.0 flows.

## Why Use Certificate Authentication?

- **Enhanced Security**: Certificates are more secure than passwords and harder to compromise
- **Better Audit Trail**: Certificate-based authentication is easier to audit and rotate
- **Microsoft Recommendation**: Microsoft recommends certificate-based authentication over client secrets
- **No Password Expiration**: Unlike client secrets, certificates don't expire automatically; you control the expiration

## Implementation Details

### Authentication Methods

The plugin now supports two authentication methods:

1. **Client Secret (Legacy)**: Uses a client ID and secret
   - Simpler to set up
   - Credentials are set via environment variables
   - Suitable for testing/development

2. **Certificate (Recommended)**: Uses a client ID and private certificate
   - More secure production approach
   - Supports .pem and .pfx certificate formats
   - Password-protected certificates are supported

### Architecture Changes

#### New Classes

- `EntraId::Graph::JwtBuilder`: Generates JWT tokens using certificate-based authentication
  - Supports RS256 algorithm
  - Handles both PEM and PFX certificate formats
  - Supports password-protected certificates
  - Calculates certificate thumbprint for Azure/Entra ID

#### Modified Classes

- `EntraId::Graph::AccessToken`: Extended to support JWT-based token requests
  - Detects authentication method and uses appropriate grant type
  - Uses `urn:ietf:params:oauth:grant-type:jwt-bearer` for certificate auth
  - Falls back to `client_credentials` for secret-based auth

- `EntraId`: Added configuration methods
  - `auth_method`: Returns current authentication method
  - `certificate_path`: Returns certificate file path
  - `certificate_password`: Returns certificate password (if any)
  - Updated `valid?`: Validates configuration based on selected method

### Configuration

#### Environment Variables

```bash
# Always required
ENTRA_ID_CLIENT_ID="your-client-id"
ENTRA_ID_TENANT_ID="your-tenant-id"

# Choose one of these:

# For Client Secret method:
ENTRA_ID_AUTH_METHOD="secret"
ENTRA_ID_CLIENT_SECRET="your-secret"

# For Certificate method:
ENTRA_ID_AUTH_METHOD="certificate"
ENTRA_ID_CERTIFICATE_PATH="/path/to/certificate.pem"
ENTRA_ID_CERTIFICATE_PASSWORD="optional-password"  # Only if certificate is encrypted
```

#### Plugin Settings (Admin UI)

The plugin now includes a configuration UI to:
- Select between "Client Secret" and "Certificate" authentication methods
- Display current configuration status
- Accept certificate paths and passwords
- Provides helpful information about each setting

### Certificate Formats

#### PEM Format
- Standard text-based format
- Can contain private key and certificate
- Example file extensions: `.pem`, `.key`, `.crt`

```pem
-----BEGIN PRIVATE KEY-----
[base64 encoded key]
-----END PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
[base64 encoded certificate]
-----END CERTIFICATE-----
```

#### PFX/PKCS#12 Format
- Binary format containing both private key and certificate
- Usually password-protected
- Example file extensions: `.pfx`, `.p12`

### JWT Claims

The generated JWT includes:
- `iss` (issuer): Client ID
- `sub` (subject): Client ID
- `aud` (audience): Token endpoint URL
- `exp` (expiration): 10 minutes from generation
- `iat` (issued at): Current timestamp
- `jti` (JWT ID): Unique identifier

## Usage Examples

### Scenario 1: Migrating from Client Secret to Certificate

1. Generate a certificate (see README for instructions)
2. Upload certificate to Entra ID
3. Set environment variables:
   ```bash
   export ENTRA_ID_AUTH_METHOD="certificate"
   export ENTRA_ID_CERTIFICATE_PATH="/etc/redmine/certs/entra.pem"
   unset ENTRA_ID_CLIENT_SECRET  # Optional: remove old secret
   ```
4. Restart Redmine
5. Verify via plugin configuration UI

### Scenario 2: Using Password-Protected Certificate

1. Generate password-protected certificate
2. Set environment variables:
   ```bash
   export ENTRA_ID_AUTH_METHOD="certificate"
   export ENTRA_ID_CERTIFICATE_PATH="/etc/redmine/certs/entra.pfx"
   export ENTRA_ID_CERTIFICATE_PASSWORD="my-secure-password"
   ```
3. Restart Redmine

### Scenario 3: Development with Self-Signed Certificate

```bash
# Generate self-signed certificate
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365

# Configure
export ENTRA_ID_AUTH_METHOD="certificate"
export ENTRA_ID_CERTIFICATE_PATH="./cert.pem"
```

## Error Handling

The plugin provides clear error messages for certificate-related issues:

- `"Failed to generate JWT: ..."` - Problem creating JWT token
- `"Failed to load certificate: ..."` - Certificate file format or read error
- `"Failed to load PFX certificate: ..."` - Issues reading password-protected PFX

## Security Considerations

1. **File Permissions**: Ensure certificate files are readable only by the Redmine process
   ```bash
   chmod 600 /etc/redmine/certs/entra.pem
   chown redmine:redmine /etc/redmine/certs/entra.pem
   ```

2. **Password Management**: 
   - Store certificate password in environment variables or secure vaults
   - Never commit passwords to version control
   - Use system secrets management (e.g., systemd EnvironmentFile)

3. **Certificate Rotation**:
   - Monitor certificate expiration dates
   - Plan rotation before expiration
   - Test new certificate before removing old one

4. **Audit Logging**: Enable Entra ID audit logs to track certificate usage

## Testing

Tests are included in:
- `test/unit/entra_id/graph/jwt_builder_test.rb`: JWT generation tests
- `test/integration/entra_id/certificate_auth_test.rb`: Integration tests

Run tests with:
```bash
bundle exec rake test TEST=test/unit/entra_id/graph/jwt_builder_test.rb
bundle exec rake test TEST=test/integration/entra_id/certificate_auth_test.rb
```

## Troubleshooting

### JWT Generation Fails
- Verify certificate file exists and is readable
- Check certificate format (PEM or PFX)
- For encrypted certificates, verify password is correct
- Check certificate is not expired

### Certificate Not Found
- Verify `ENTRA_ID_CERTIFICATE_PATH` is correct
- Check file permissions (must be readable by Redmine process)
- Verify certificate file is not corrupted

### Entra ID Rejects JWT
- Ensure certificate public key is uploaded to Entra ID
- Verify certificate is not expired
- Check certificate thumbprint matches what's expected
- Ensure client ID matches what's configured in Entra ID

## Migration from Client Secret

If you're currently using client secret authentication:

1. Create and upload certificate to Entra ID
2. Set `ENTRA_ID_AUTH_METHOD="certificate"`
3. Set `ENTRA_ID_CERTIFICATE_PATH` to certificate location
4. Restart Redmine - plugin will automatically use certificate
5. Verify sync and authentication work
6. Remove client secret from Entra ID (optional but recommended)
7. Remove `ENTRA_ID_CLIENT_SECRET` environment variable

## Future Enhancements

Potential improvements:
- Certificate upload directly via admin UI
- Automatic certificate expiration warnings
- Certificate rotation scheduling
- Multiple certificates for rotation
- HSM (Hardware Security Module) support

## References

- [Microsoft Entra ID - Manage certificates](https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#option-1-upload-a-certificate)
- [OAuth 2.0 JWT Bearer Assertion](https://tools.ietf.org/html/rfc7523)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
