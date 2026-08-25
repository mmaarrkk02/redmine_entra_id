# Entra ID 證書認證支援 / Certificate Authentication Support

## 中文說明 / Chinese

### 概述
本次更新為 Redmine Entra ID 插件添加了基於證書的認證支援。由於 Microsoft 已禁用客戶端密碼認證，此功能提供了一個更安全的替代方案。

### 主要特點
- ✅ 支持 `.pem` 和 `.pfx` 證書格式
- ✅ 支持密碼保護的證書
- ✅ JWT 簽署的 OAuth 2.0 流程
- ✅ 完全向後兼容（默認仍使用客戶端密碼）
- ✅ 動態 UI 配置
- ✅ 詳細的文檔和快速入門指南

### 快速開始

#### 步驟 1: 生成證書
```bash
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
```

#### 步驟 2: 上傳到 Entra ID
1. 前往 [Microsoft Entra 管理中心](https://entra.microsoft.com)
2. **Entra ID** → **應用註冊** → 您的應用
3. **證書和密碼** → **證書**
4. 點擊 **上傳證書** 並選擇 `cert.pem`

#### 步驟 3: 配置 Redmine
```bash
export ENTRA_ID_CLIENT_ID="your-client-id"
export ENTRA_ID_TENANT_ID="your-tenant-id"
export ENTRA_ID_AUTH_METHOD="certificate"
export ENTRA_ID_CERTIFICATE_PATH="/path/to/cert.pem"

# 重啟 Redmine
systemctl restart redmine
```

#### 步驟 4: 驗證
- 進入 **管理** > **插件** > **Entra ID** > **配置**
- 驗證認證方法已設置為「證書」

---

## English

### Overview
This update adds certificate-based authentication support to the Redmine Entra ID plugin. Since Microsoft has deprecated client password authentication, this feature provides a more secure alternative.

### Key Features
- ✅ Support for `.pem` and `.pfx` certificate formats
- ✅ Support for password-protected certificates
- ✅ JWT-signed OAuth 2.0 flow
- ✅ Fully backward compatible (defaults to client secret)
- ✅ Dynamic UI configuration
- ✅ Comprehensive documentation and quick start guide

### Quick Start

#### Step 1: Generate Certificate
```bash
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
```

#### Step 2: Upload to Entra ID
1. Go to [Microsoft Entra admin center](https://entra.microsoft.com)
2. **Entra ID** → **App registrations** → Your app
3. **Certificates & secrets** → **Certificates**
4. Click **Upload certificate** and select `cert.pem`

#### Step 3: Configure Redmine
```bash
export ENTRA_ID_CLIENT_ID="your-client-id"
export ENTRA_ID_TENANT_ID="your-tenant-id"
export ENTRA_ID_AUTH_METHOD="certificate"
export ENTRA_ID_CERTIFICATE_PATH="/path/to/cert.pem"

# Restart Redmine
systemctl restart redmine
```

#### Step 4: Verify
- Go to **Administration** > **Plugins** > **Entra ID** > **Configure**
- Verify that authentication method is set to "Certificate"

---

## Implementation Files / 實現文件

### Core Changes / 核心變更

| File | Type | Purpose |
|------|------|---------|
| `lib/entra_id/graph/jwt_builder.rb` | NEW | JWT token generation for certificate auth |
| `lib/entra_id/graph/access_token.rb` | MODIFIED | Support both secret and certificate methods |
| `lib/entra_id.rb` | MODIFIED | Add certificate configuration methods |
| `init.rb` | MODIFIED | Version 1.1.0, new settings |
| `app/views/settings/_entra_id.html.erb` | MODIFIED | UI for auth method selection |
| `app/controllers/concerns/entra_id/maskable_settings.rb` | MODIFIED | Handle certificate password safely |
| `config/locales/en.yml` | MODIFIED | New translation strings |

### Testing Files / 測試文件

| File | Type | Purpose |
|------|------|---------|
| `test/unit/entra_id/graph/jwt_builder_test.rb` | NEW | JWT builder unit tests |
| `test/integration/entra_id/certificate_auth_test.rb` | NEW | Integration tests |
| `test/support/entra_id_env_helper.rb` | MODIFIED | Certificate env setup helpers |

### Documentation Files / 文檔文件

| File | Purpose |
|------|---------|
| `README.md` | Updated with certificate setup instructions |
| `CHANGELOG.md` | Version 1.1.0 release notes |
| `CERTIFICATE_AUTH.md` | Comprehensive certificate authentication guide |
| `QUICK_START_CERTIFICATE.md` | Quick reference and examples |
| `IMPLEMENTATION_SUMMARY.md` | Detailed implementation overview |

---

## Configuration Methods / 配置方式

### Method 1: Environment Variables (Recommended)
```bash
export ENTRA_ID_CLIENT_ID="your-client-id"
export ENTRA_ID_TENANT_ID="your-tenant-id"
export ENTRA_ID_AUTH_METHOD="certificate"
export ENTRA_ID_CERTIFICATE_PATH="/path/to/cert.pem"
export ENTRA_ID_CERTIFICATE_PASSWORD="optional-password"
```

### Method 2: Admin UI
1. Administration → Plugins → Entra ID → Configure
2. Select "Certificate" from Authentication Method dropdown
3. Set certificate path and password (if needed)
4. Save

### Method 3: Hybrid (Recommended for Production)
- Set client ID and tenant ID via environment variables
- Set auth method and certificate path via environment variables
- Certificate password optional via environment variables
- Falls back to database settings if env vars not set

---

## Migration Guide / 遷移指南

### From Client Secret to Certificate

1. **Prepare Certificate**
   ```bash
   # Generate or obtain certificate
   openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365
   ```

2. **Upload to Entra ID**
   - Upload certificate public key to Azure/Entra ID

3. **Update Configuration**
   ```bash
   export ENTRA_ID_AUTH_METHOD="certificate"
   export ENTRA_ID_CERTIFICATE_PATH="/etc/redmine/certs/cert.pem"
   ```

4. **Test**
   - Restart Redmine
   - Verify plugin configuration in admin UI
   - Run sync: `bundle exec rake entra_id:sync`

5. **Cleanup (Optional)**
   - Remove `ENTRA_ID_CLIENT_SECRET` environment variable
   - Delete old secret from Entra ID

---

## Troubleshooting / 故障排除

### Common Issues / 常見問題

| Issue | Solution |
|-------|----------|
| Certificate file not found | Check path in ENTRA_ID_CERTIFICATE_PATH |
| Wrong password for certificate | Verify ENTRA_ID_CERTIFICATE_PASSWORD |
| JWT generation failed | Check certificate is not expired |
| Entra ID rejects request | Verify certificate is uploaded to Entra ID |

### Debug Commands / 調試命令

```bash
# Check certificate details
openssl x509 -in cert.pem -text -noout

# Check certificate expiration
openssl x509 -in cert.pem -noout -dates

# Check certificate thumbprint
openssl x509 -in cert.pem -noout -fingerprint -sha1

# Check Redmine logs
tail -f /path/to/redmine.log | grep -i "entra\|jwt\|certificate"
```

---

## Security Considerations / 安全注意事項

✅ **Best Practices**

1. **File Permissions**
   ```bash
   chmod 600 /etc/redmine/certs/cert.pem
   chown redmine:redmine /etc/redmine/certs/cert.pem
   ```

2. **Environment Variables**
   - Use systemd EnvironmentFile
   - Use secrets management (Vault, etc.)
   - Never commit to version control

3. **Certificate Rotation**
   - Monitor expiration dates
   - Rotate before expiration
   - Test new certificate first

4. **Audit Logging**
   - Enable Entra ID audit logs
   - Monitor certificate usage

---

## Supported Formats / 支持的格式

### PEM Format (Text)
- Private key + certificate in one file
- Readable with text editor
- Optional password protection

### PFX/PKCS#12 Format (Binary)
- Private key + certificate bundled
- Usually password-protected
- Better for automated deployment

### Conversion Commands / 轉換命令

```bash
# PEM to PFX
openssl pkcs12 -export -in cert.pem -inkey key.pem -out cert.pfx

# PFX to PEM
openssl pkcs12 -in cert.pfx -out cert.pem -nodes
```

---

## Version Info / 版本信息

- **Plugin Version**: 1.1.0
- **Minimum Redmine**: 5.x
- **Required Ruby**: 3.1+
- **Dependencies**: jwt gem (already included)

---

## Documentation References / 文檔參考

- 📖 **Detailed Guide**: [CERTIFICATE_AUTH.md](./CERTIFICATE_AUTH.md)
- 🚀 **Quick Start**: [QUICK_START_CERTIFICATE.md](./QUICK_START_CERTIFICATE.md)
- 📋 **Implementation**: [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md)
- 📝 **Main README**: [README.md](./README.md)

---

## Support / 支持

For issues, questions, or contributions:
- GitHub: https://github.com/eea/redmine_entra_id
- Issues: https://github.com/eea/redmine_entra_id/issues

遇到問題、有疑問或想貢獻：
- GitHub: https://github.com/eea/redmine_entra_id
- 問題報告: https://github.com/eea/redmine_entra_id/issues
