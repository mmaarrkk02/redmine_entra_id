# Certificate Authentication Quick Start

## 30-Second Setup

### Step 1: Generate Certificate (if needed)
```bash
# For testing
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes

# For production (with password)
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365
# Follow prompts to set password
```

### Step 2: Upload to Entra ID
1. Go to [Microsoft Entra admin center](https://entra.microsoft.com)
2. **Entra ID** → **App registrations** → Your app
3. **Certificates & secrets** → **Certificates**
4. Click **Upload certificate**
5. Select your `cert.pem` file

### Step 3: Configure Redmine
```bash
# Set environment variables
export ENTRA_ID_CLIENT_ID="your-client-id"
export ENTRA_ID_TENANT_ID="your-tenant-id"
export ENTRA_ID_AUTH_METHOD="certificate"
export ENTRA_ID_CERTIFICATE_PATH="/path/to/cert.pem"
# Optional (if certificate is password-protected):
# export ENTRA_ID_CERTIFICATE_PASSWORD="your-password"

# Restart Redmine
systemctl restart redmine
```

### Step 4: Verify
- Go to **Administration** > **Plugins** > **Entra ID** > **Configure**
- Select "Certificate" in Authentication Method
- Verify settings display correctly

## Common Commands

### Check Certificate Expiration
```bash
openssl x509 -in cert.pem -noout -dates
```

### Convert PFX to PEM
```bash
openssl pkcs12 -in cert.pfx -out cert.pem -nodes
```

### Verify Thumbprint
```bash
openssl x509 -in cert.pem -noout -fingerprint -sha1
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Certificate not found" | Check path is correct and file is readable |
| "Invalid password" | Verify password is correct if certificate encrypted |
| "JWT generation failed" | Check certificate is not corrupted or expired |
| "Entra ID rejects request" | Ensure certificate is uploaded to Entra ID |

## Docker Example

```dockerfile
# Copy certificate into container
COPY certs/entra.pem /etc/redmine/certs/

# Set environment at startup
ENV ENTRA_ID_AUTH_METHOD=certificate
ENV ENTRA_ID_CERTIFICATE_PATH=/etc/redmine/certs/entra.pem

# Set permissions
RUN chmod 600 /etc/redmine/certs/entra.pem
```

## Kubernetes Example

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: entra-cert
data:
  cert.pem: <base64-encoded-certificate>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redmine
spec:
  template:
    spec:
      containers:
      - name: redmine
        env:
        - name: ENTRA_ID_AUTH_METHOD
          value: "certificate"
        - name: ENTRA_ID_CERTIFICATE_PATH
          value: "/mnt/certs/cert.pem"
        volumeMounts:
        - name: entra-cert
          mountPath: /mnt/certs
      volumes:
      - name: entra-cert
        secret:
          secretName: entra-cert
```

## Next Steps

- Read [CERTIFICATE_AUTH.md](./CERTIFICATE_AUTH.md) for detailed documentation
- Read [README.md](./README.md) for full plugin configuration
- Review security best practices in this guide
