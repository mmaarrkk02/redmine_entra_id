# Changelog

## 1.0.0

- Redmine 6.1 compliance
- `sync:users` no longer reactivates users already `locked` in Redmine
- `sync:users` locks users with `@discomap.eea.europa.eu` email addresses on create and update
- tests updated for the new user sync status policy
- EEA Entra ID sync policy integrated into `README.md`

## 0.0.1

- initial Entra ID OAuth login support
- automatic user creation and identity linking
- Entra ID user sync with OID and sync timestamp storage
- Entra ID group sync and membership reconciliation
- plugin configuration UI, exclusive mode, and admin sync visibility
- test suite, Graph client integration, and project documentation
