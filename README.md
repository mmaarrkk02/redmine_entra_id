# Redmine EntraID Plugin

A Redmine plugin that enables Microsoft EntraID (formerly Azure Active Directory) authentication and user synchronization for your Redmine installation.

## What is Microsoft EntraID?

Microsoft EntraID is Microsoft's cloud-based identity and access management service that helps employees sign in and access resources. It's the evolution of Azure Active Directory and provides:

- Single Sign-On (SSO)
- Centralized User Management
- Enhanced Security
- OAuth 2.0 Integration

## Plugin features

- **OAuth 2.0 Authentication**: Secure login using Microsoft EntraID credentials with
  automatic user creation
- **User Synchronization**: One-way sync of EntraId users to Redmine
- **Group Synchronization**: One-way sync of EntraID groups and memberships to Redmine
- **Exclusive Mode**: Option to disable local Redmine authentication entirely

## Requirements

- Redmine 5.x, 6.0, and 6.1
- Ruby 3.1 or newer
- Microsoft EntraID tenant with application registration

## Installation

1. **Clone the plugin into your Redmine plugins directory:**

   ```bash
   cd /path/to/redmine
   git clone https://github.com/eea/redmine_entra_id.git plugins/entra_id
   ```

2. **Install plugin dependencies:**

   ```bash
   bundle install
   ```

3. **Run the plugin migrations from the Redmine root directory:**

   ```bash
   bundle exec rake redmine:plugins:migrate RAILS_ENV=production
   ```

4. **Restart your Redmine application server**

## Microsoft Entra ID Setup

These steps need to be completed in the EntraID admin console.

1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com)
2. Navigate to **Entra ID** > **App registrations**
3. Click **New registration**
4. Configure:
   - **Name**: Redmine
   - **Supported account types**: Accounts in this organizational directory only
   - **Redirect URI**: `https://your-redmine-domain.com/entra_id/callback`
5. Go to **API permissions**
6. Add the following **Microsoft Graph** permissions:
   - **User.Read** (Delegated) - for user authentication
   - **User.Read.All** (Application) - for user synchronization
   - **Group.Read.All** (Application) - for group synchronization
7. Click **Grant admin consent** to apply the permissions

### Authentication Method Setup

Choose one of the following authentication methods:

#### Option 1: Client Secret (Legacy)

8. Go to **Certificates & secrets**
9. Click **New client secret**
10. Add a description and set expiration
11. **Copy the secret value** (you won't be able to see it again)

#### Option 2: Certificate (Recommended)

8. Go to **Certificates & secrets** → **Certificates**
9. Click **Upload certificate**
10. Upload your certificate file (.pem or .pfx)
11. Note: Ensure the certificate's public key is uploaded to Entra ID

From your app registration overview page, copy:

- **Application (client) ID**
- **Directory (tenant) ID**
- **Client secret** (if using client secret method)
- **Certificate path** (if using certificate method)

## Plugin Configuration

1. **Navigate to Redmine Administration**

   - Go to **Administration** > **Plugins**
   - Find "Entra ID" and click **Configure**

2. **Configure the plugin:**

   The plugin uses environment variables for the Entra credentials.

   ### Using Client Secret (Legacy Method)

   ```bash
   export ENTRA_ID_CLIENT_ID="12345678-1234-1234-1234-123456789012"
   export ENTRA_ID_CLIENT_SECRET="your-client-secret-here"
   export ENTRA_ID_TENANT_ID="87654321-4321-4321-4321-210987654321"
   export ENTRA_ID_AUTH_METHOD="secret"
   ```

   ### Using Certificate (Recommended Method)

   ```bash
   export ENTRA_ID_CLIENT_ID="12345678-1234-1234-1234-123456789012"
   export ENTRA_ID_TENANT_ID="87654321-4321-4321-4321-210987654321"
   export ENTRA_ID_AUTH_METHOD="certificate"
   export ENTRA_ID_CERTIFICATE_PATH="/path/to/certificate.pem"
   # Optional: if certificate is password-protected
   export ENTRA_ID_CERTIFICATE_PASSWORD="your-certificate-password"
   ```

   **Certificate Format Support:**
   - `.pem` files (with or without password)
   - `.pfx` / `.p12` files (with password)

   **Plugin Settings** (via Administration > Plugins > Configure):

   | Setting              | Description                          | Default    |
   | -------------------- | ------------------------------------ | ---------- |
   | **Enabled**          | Enable/disable the plugin            | `false`    |
   | **Exclusive**        | Disable local Redmine authentication | `false`    |
   | **Authentication Method** | Choose between secret or certificate | `secret`  |
   | **Certificate Path** | Path to certificate file (cert method only) | (empty) |
   | **Certificate Password** | Password for encrypted certificates (cert method only) | (empty) |

3. **Save the configuration**

## Usage

### User Authentication

Once configured, users will see a "Sign in with EntraId" option on the Redmine login page. The authentication flow:

1. User clicks "Log in with Microsoft EntraId"
2. Redirected to Microsoft login page
3. User enters corporate credentials
4. Microsoft redirects back to Redmine with authorization code
5. Plugin exchanges code for user information
6. User is logged into Redmine (account created if needed)

### User and Group Synchronization

The plugin provides rake tasks for synchronizing users and groups:

```bash
# Sync both users and groups
bundle exec rake entra_id:sync RAILS_ENV=production

# Sync only users
bundle exec rake entra_id:sync:users RAILS_ENV=production

# Sync only groups
bundle exec rake entra_id:sync:groups RAILS_ENV=production
```

**User Synchronization**:

- Fetches all users from Microsoft Graph API
- Creates/updates local Redmine users
- Maps Entra ID attributes to Redmine fields:
  - `userPrincipalName` → login/email
  - `givenName` → firstname
  - `surname` → lastname
  - `id` (OID) → stored for future synchronization
- Updates `synced_at` timestamp
- Keeps already `locked` Redmine users locked during sync
- Locks users whose Entra email is under `@discomap.eea.europa.eu`, both on create and update

**Group Synchronization**:

- Fetches groups from Microsoft Graph API
- Creates/updates Redmine groups based on EntraID groups
- Syncs group memberships automatically

### Admin edit forms

The plugin also exposes Entra ID metadata directly in the Redmine edit forms:

- **User edit**: displays the Entra ID OID and the `EEA Entra ID synced at` timestamp in the `Information` fieldset
- **Group edit**: displays the Entra ID OID and the `EEA Entra ID synced at` timestamp in the `Information` fieldset
- **Group edit layout**: uses separate `Information` and `Authentication` fieldsets, matching the structure of the user edit form

### EEA Entra ID Sync Policy

This section documents the synchronization policy currently implemented by the plugin.

`entra_id:sync` runs, in order:

1. user synchronization
2. group synchronization

**Current user sync policy**:

1. Reads users from the Microsoft Graph `users` endpoint
2. For each Entra ID user, looks for a local Redmine user by `oid`, email, then login
3. If the user exists in Redmine, updates `firstname`, `lastname`, `mail`, `oid`, `status`, and `synced_at`
4. If the user does not exist in Redmine, creates it

**User attributes synchronized**:

- `id` -> `oid`
- `mail` or `userPrincipalName` -> `mail`
- `mail` or `userPrincipalName` -> `login` on create only
- `givenName` / `surname` / `displayName` -> `firstname`, `lastname`
- synchronization time -> `synced_at`

**User status policy**:

- existing users that are already `locked` in Redmine remain `locked`
- users with email addresses under `@discomap.eea.europa.eu` are always set to `locked`
- all other synchronized users are set to `active`

**What user sync explicitly does**:

- updates existing users returned by Entra ID
- creates new users returned by Entra ID
- updates `synced_at` on every successful synchronization
- does not update `login` for existing users

**What user sync does not do**:

- if a user has been deleted from Entra ID, no action is taken on the Redmine user
- if a user no longer appears in the sync result, the user is not deleted from Redmine
- if a user no longer appears in the sync result, the user is not locked in Redmine
- if a user is disabled in Entra ID, the current plugin does not detect this and does not lock the user in Redmine
- there is no reconciliation for users previously synchronized but now absent from Entra ID
- there is no delta sync for users

**Current group sync policy**:

1. Reads groups from the Microsoft Graph `groups` endpoint
2. For each group, reads members from `transitiveMembers`
3. Creates or updates the corresponding Redmine group
4. Reconciles Redmine group membership against the membership returned by Entra ID

**What group sync explicitly does**:

- creates new groups in Redmine
- updates existing groups by `oid`
- updates the Redmine group name from Entra ID
- adds users that already exist in Redmine and have a matching `oid`
- removes users that are in the Redmine group but no longer appear in the Entra ID group membership
- removes users without an `oid` from synchronized groups

**What group sync does not do**:

- if a group has been deleted from Entra ID, no action is taken on the Redmine group
- groups missing from Entra ID are not deleted from Redmine
- groups missing from Entra ID are not archived and are not marked in any way
- group sync does not create missing users; it only adds users that already exist locally and are identified by `oid`
- group sync does not lock or delete users
- there is no delta sync for groups

### Exclusive Mode

When **Exclusive** mode is enabled:

- Local Redmine authentication is disabled
- Only Entra ID users can log in
- Registration and password reset forms are hidden
- Useful for corporate environments requiring centralized authentication

## Database Changes

The plugin adds the following fields to the `users` table:

- `oid` (string): Microsoft Entra ID Object ID (unique identifier)
- `synced_at` (datetime): Last synchronization timestamp

## Update scripts

- `bin/rails entra_id:reset_logins`
- `bin/rails entra_id:reset_auth_sources`

## Certificate Management (for Certificate Authentication)

### Generating a Self-Signed Certificate

If you need to generate a certificate for testing or development:

```bash
# Generate a private key
openssl genrsa -out private.key 2048

# Generate a self-signed certificate valid for 365 days
openssl req -new -x509 -key private.key -out certificate.pem -days 365

# Combine into a single PEM file (if needed)
cat private.key certificate.pem > combined.pem
```

### Converting Between Formats

```bash
# PEM to PFX (PKCS#12)
openssl pkcs12 -export -in certificate.pem -inkey private.key -out certificate.pfx

# PFX to PEM
openssl pkcs12 -in certificate.pfx -out certificate.pem -nodes
```

### Uploading Certificate to Entra ID

1. In the Microsoft Entra admin center, go to **App registrations** → your app
2. Navigate to **Certificates & secrets** → **Certificates**
3. Click **Upload certificate**
4. Select your certificate file (.pem, .cer, or .pfx)
5. Click **Add**

### Certificate Expiration Management

Certificates have expiration dates. Monitor your certificate expiration:

```bash
# Check certificate expiration date
openssl x509 -in certificate.pem -noout -dates
```

Set up reminders to:
- Generate a new certificate before the current one expires
- Upload the new certificate to Entra ID
- Update the `ENTRA_ID_CERTIFICATE_PATH` environment variable
- Restart your Redmine application

## Troubleshooting

### Common Issues

**"Invalid redirect URI" error:**

- Ensure the redirect URI in Azure matches exactly: `https://your-domain.com/entra_id/callback`
- Check for trailing slashes and protocol (http vs https)

**"Insufficient privileges" error:**

- Verify application permissions are configured correctly
- Ensure admin consent has been granted for your organization

**"Invalid client" error:**

- Double-check Client ID and Tenant ID values
- Ensure Client Secret hasn't expired (if using secret method)
- Ensure certificate is valid and uploaded to Entra ID (if using certificate method)

**"Failed to generate JWT" error:**

- Verify the certificate file path is correct
- Ensure the certificate file is readable by the Redmine process
- If using a password-protected certificate, verify `ENTRA_ID_CERTIFICATE_PASSWORD` is set correctly
- Ensure certificate is not expired

**"Failed to load certificate" error:**

- Check that the certificate file format is supported (.pem or .pfx)
- For .pfx files, ensure the password is correct
- Verify the certificate file is not corrupted

## Contributing

### Local setup

Clone the Redmine repository:

```bash
gh repo clone redmine/redmine
```

Clone the plugin in the Redmine plugins folder in the `plugins/entra_id` folder of the Redmine installation:

```bash
gh repo clone eea/redmine_entra_id redmine/plugins/entra_id
```

Create a database configuration for Redmine. Below is a sample configuration for MySQL 8 or newer:

```yaml
default: &default
  adapter: mysql2
  host: 127.0.0.1
  username: root
  encoding: utf8mb4
  variables:
    # Recommended `transaction_isolation` for MySQL to avoid concurrency issues is
    # `READ-COMMITTED`.
    # In case of MySQL lower than 8, the variable name is `tx_isolation`.
    # See https://www.redmine.org/projects/redmine/wiki/MySQL_configuration
    transaction_isolation: "READ-COMMITTED"

development:
  <<: *default
  database: redmine_development

test:
  <<: *default
  database: redmine_test

production:
  <<: *default
  database: redmine_production
```

Setup the database:

```bash
bin/rails db:prepare
```

Load the default Redmine data:

```bash
bin/rails redmine:load_default_data REDMINE_LANG=en
```

Run the plugin migrations:

```bash
bin/rails redmine:plugins:migrate NAME=entra_id
```
