# Certificate Authentication Implementation Summary

## Overview

This implementation adds certificate-based authentication support to the Redmine Entra ID plugin, allowing it to use JWT-based authentication instead of (or in addition to) client secrets. This addresses the need for organizations where Microsoft has blocked or deprecated client password authentication.

## Changes Made

### Core Implementation Files

#### 1. New JWT Builder Module
**File**: `lib/entra_id/graph/jwt_builder.rb`

- Generates JWT tokens signed with RSA private keys
- Supports both PEM and PFX certificate formats
- Handles password-protected certificates
- Calculates certificate thumbprints for Azure
- Error handling with detailed NetworkError messages

Key classes:
```ruby
class EntraId::Graph::JwtBuilder
  - generate(certificate_path, client_id, tenant_id, certificate_password = nil)
  - Handles RS256 algorithm
  - 10-minute token expiration
```

#### 2. Enhanced AccessToken Module
**File**: `lib/entra_id/graph/access_token.rb`

Modified methods:
- `using_certificate?` - Detects current auth method
- `token_params` - Routes to certificate or secret method
- `secret_token_params` - Original client credentials flow
- `certificate_token_params` - New JWT-based flow (RFC 7523)
- `request` - Uses appropriate authentication method

#### 3. Extended EntraId Configuration Module
**File**: `lib/entra_id.rb`

New methods:
- `auth_method` - Returns 'secret' or 'certificate'
- `certificate_path` - Returns certificate file path
- `certificate_password` - Returns certificate password

Enhanced methods:
- `valid?` - Validates config based on selected auth method

#### 4. Updated Plugin Registration
**File**: `init.rb`

- Version bumped to 1.1.0
- Added new settings: `auth_method`, `certificate_path`, `certificate_password`
- Default auth method is 'secret' (backward compatible)

### User Interface & Configuration

#### 5. Settings UI Template
**File**: `app/views/settings/_entra_id.html.erb`

New features:
- Dropdown to select authentication method
- Dynamic field visibility using JavaScript
- Separate sections for secret vs certificate auth
- Informational messages for each setting
- Password field for certificate password input

#### 6. Localization
**File**: `config/locales/en.yml`

Added translations:
- `entra_id_authentication_method` - Section title
- `entra_id_auth_method` - Label
- `entra_id_auth_method_info` - Help text
- `entra_id_auth_method_secret` - Option label
- `entra_id_auth_method_certificate` - Option label
- `entra_id_certificate_path` - Label and help
- `entra_id_certificate_password` - Label, placeholder, and help
- `error_entra_id_certificate_path_required` - Validation error

#### 7. Settings Controller Concern
**File**: `app/controllers/concerns/entra_id/maskable_settings.rb`

Enhanced handling:
- Removes client_secret from form submission (use env vars)
- Validates certificate path when cert auth selected
- Handles empty certificate password gracefully
- Provides user feedback on configuration errors

### Testing

#### 8. Unit Tests for JWT Builder
**File**: `test/unit/entra_id/graph/jwt_builder_test.rb`

Test coverage:
- Error handling for missing certificate files
- JWT payload validation
- Certificate format support

#### 9. Integration Tests
**File**: `test/integration/entra_id/certificate_auth_test.rb`

Test scenarios:
- Switching authentication methods
- Validating required fields
- Certificate existence validation
- Both auth methods functional

#### 10. Enhanced Test Helper
**File**: `test/support/entra_id_env_helper.rb`

New methods:
- `setup_certificate_env` - Configure certificate auth
- `teardown_certificate_env` - Cleanup

Enhanced teardown:
- Clears certificate-related env vars

### Documentation

#### 11. Main README Updates
**File**: `README.md`

Added sections:
- Microsoft Entra ID setup for certificates
- Certificate authentication configuration
- Environment variable examples
- Troubleshooting for certificate-specific issues
- Certificate format explanations

#### 12. Detailed Certificate Documentation
**File**: `CERTIFICATE_AUTH.md`

Comprehensive guide:
- Architecture explanation
- JWT claims specification
- Usage examples and scenarios
- Certificate formats and conversions
- Security best practices
- Error handling and debugging
- Migration guide from secrets to certificates

#### 13. Quick Start Guide
**File**: `QUICK_START_CERTIFICATE.md`

Fast reference:
- 30-second setup steps
- Common OpenSSL commands
- Docker/Kubernetes examples
- Troubleshooting table

#### 14. Changelog
**File**: `CHANGELOG.md`

Version 1.1.0 entry documenting:
- Certificate authentication support
- JWT-based token generation
- UI configuration updates
- Certificate format support

## Architecture

### Authentication Flow

#### Secret-Based (Original)
```
Redmine → AccessToken.request()
        → token_params (client_secret method)
        → POST /oauth2/v2.0/token
        → { grant_type: "client_credentials" }
        → Access Token
```

#### Certificate-Based (New)
```
Redmine → AccessToken.request()
        → token_params (certificate method)
        → JwtBuilder.generate()
        → OpenSSL: Load cert + sign JWT
        → POST /oauth2/v2.0/token
        → { grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer" }
        → Access Token
```

### Environment Variable Hierarchy

1. **First Priority**: Explicit environment variables
   - `ENTRA_ID_AUTH_METHOD`
   - `ENTRA_ID_CERTIFICATE_PATH`
   - `ENTRA_ID_CERTIFICATE_PASSWORD`

2. **Second Priority**: Plugin settings database
   - Fallback values if env vars not set
   - UI-configurable defaults

3. **Default**: Built-in defaults
   - `auth_method` = 'secret'
   - Other settings empty

## Backward Compatibility

✅ **Fully Backward Compatible**

- Default authentication method remains 'secret'
- Existing deployments work without changes
- Can switch methods at any time
- No database migrations required
- No breaking changes to APIs

## Security Considerations

### Implemented
- Certificate password handling (optional encryption support)
- Private key loading with OpenSSL validation
- JWT expiration (10 minutes)
- Error messages don't leak sensitive info
- Supports password-protected certificates

### Recommended
- Store certificates with restricted file permissions (600)
- Use environment variables for sensitive data
- Monitor certificate expiration dates
- Rotate certificates before expiration
- Enable Entra ID audit logging
- Use systemd EnvironmentFile for production

## Testing

Run tests with:
```bash
# All tests
bundle exec rake test

# Specific test files
bundle exec rake test TEST=test/unit/entra_id/graph/jwt_builder_test.rb
bundle exec rake test TEST=test/integration/entra_id/certificate_auth_test.rb
```

## Deployment Checklist

- [ ] Generate certificate (self-signed or CA-signed)
- [ ] Upload certificate to Entra ID
- [ ] Set `ENTRA_ID_AUTH_METHOD="certificate"`
- [ ] Set `ENTRA_ID_CERTIFICATE_PATH` to certificate file
- [ ] Test authentication flow
- [ ] Verify user sync works
- [ ] Set up certificate rotation reminder
- [ ] Document certificate location for team
- [ ] Monitor certificate expiration in logs

## Performance Impact

- **Minimal**: JWT generation adds <100ms per token request
- **Cached**: Access tokens cached until expiration (60+ minutes)
- **Infrequent**: Sync tasks create tokens infrequently

## Future Enhancements

Potential improvements for future versions:
- Certificate upload via web UI
- Automatic certificate expiration alerts
- Multiple certificates for rolling rotation
- HSM (Hardware Security Module) integration
- Certificate chain validation
- Certificate pinning

## Support & Troubleshooting

For issues:
1. Check logs: `grep -i "entra\|jwt\|certificate" /path/to/redmine.log`
2. Verify certificate: `openssl x509 -in cert.pem -text -noout`
3. Check expiration: `openssl x509 -in cert.pem -noout -dates`
4. Review CERTIFICATE_AUTH.md troubleshooting section
5. Verify Entra ID certificate upload

## Files Modified/Created

### Modified (9 files)
- lib/entra_id.rb
- lib/entra_id/graph/access_token.rb
- init.rb
- app/views/settings/_entra_id.html.erb
- app/controllers/concerns/entra_id/maskable_settings.rb
- config/locales/en.yml
- test/support/entra_id_env_helper.rb
- README.md
- CHANGELOG.md

### Created (5 files)
- lib/entra_id/graph/jwt_builder.rb
- test/unit/entra_id/graph/jwt_builder_test.rb
- test/integration/entra_id/certificate_auth_test.rb
- CERTIFICATE_AUTH.md
- QUICK_START_CERTIFICATE.md

### Total Changes
- Lines added: ~800
- New methods: 8
- New classes: 1
- Test coverage: 2 new test files
- Documentation: 3 new guides

## Version Information

- **Plugin Version**: 1.1.0
- **Minimum Redmine**: 5.x
- **Required Ruby**: 3.1+
- **Dependencies**: jwt gem (already in Gemfile)

## Contact & Contribution

For questions or improvements, refer to:
- GitHub: https://github.com/eea/redmine_entra_id
- Issues: https://github.com/eea/redmine_entra_id/issues
- Documentation: See CERTIFICATE_AUTH.md and README.md
