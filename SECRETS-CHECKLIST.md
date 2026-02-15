# GitHub Secrets Setup Checklist

Quick reference for setting up GitHub Actions deployment.

## Required GitHub Secrets

Go to: **Repository Settings** → **Secrets and variables** → **Actions** → **New repository secret**

### ✅ Checklist

- [ ] `TS_OAUTH_CLIENT_ID` - Tailscale OAuth Client ID
- [ ] `TS_OAUTH_SECRET` - Tailscale OAuth Client Secret  
- [ ] `SERVER_TAILSCALE_IP` - Server's Tailscale IP (e.g., `100.x.x.x`)
- [ ] `SERVER_USER` - SSH username (e.g., `msduncan82`)
- [ ] `SSH_PRIVATE_KEY` - Full SSH private key content

## Quick Commands

### Get Tailscale OAuth Credentials
Visit: https://login.tailscale.com/admin/settings/oauth
- Click "Generate OAuth client"
- Description: "GitHub Actions - Satisfactory Server"
- Scope: `devices:write`

### Get Server Tailscale IP
```bash
ssh msduncan82@192.168.50.184
tailscale ip -4
```

### Get SSH Private Key
```bash
cat ~/.ssh/darterpro_deploy
```
Copy entire output including `-----BEGIN` and `-----END` lines.

## Test Deployment

### Manual Test
1. Go to GitHub → **Actions** tab
2. Select "Deploy to DarterPro"
3. Click **Run workflow**

### Automatic Test
```bash
git commit --allow-empty -m "Test deployment"
git push origin main
```

## Verify

After deployment runs:
```bash
ssh msduncan82@100.x.x.x
cd ~/Projects/satisfactory-server
git log -1
```

---

**See GITHUB-ACTIONS-SETUP.md for detailed setup instructions.**
