# Changelog

## 1.1.0

- Support for certificate-based authentication (JWT/client assertion)
- Both client secret and certificate authentication methods now supported
- Configuration UI to select authentication method
- Support for .pem and .pfx certificate formats
- Password-protected certificate support
- Certificate management documentation and examples

## 1.0.0

- Redmine 6.1 compliance
- `sync:users` no longer reactivates users already `locked` in Redmine
- `sync:users` locks users with `@discomap.eea.europa.eu` email addresses on create and update
- show Entra ID OID on user edit and group edit pages
- show `EEA Entra ID synced at` on user edit and group edit pages
- group edit form now mirrors the user edit layout with `Information` and `Authentication` sections
- tests updated for the new user sync status policy
- EEA Entra ID sync policy integrated into `README.md`

## 0.0.1

- initial Entra ID OAuth login support
- automatic user creation and identity linking
- Entra ID user sync with OID and sync timestamp storage
- Entra ID group sync and membership reconciliation
- plugin configuration UI, exclusive mode, and admin sync visibility
- test suite, Graph client integration, and project documentation
