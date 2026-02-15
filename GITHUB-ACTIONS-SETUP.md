# GitHub Actions Deployment Setup

This guide explains how to set up automated deployments using GitHub Actions with Tailscale for secure SSH access.

## Overview

When you push to the `main` branch, GitHub Actions will:
1. Connect to your Tailscale network
2. SSH into your DarterPro server via Tailscale IP
3. Pull the latest changes from GitHub
4. Update configuration files

## Prerequisites

- Tailscale installed on your DarterPro server
- SSH access configured on the server
- GitHub repository with deploy key set up

## Step 1: Create Tailscale OAuth Credentials

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/oauth)
2. Click **Generate OAuth client**
3. Add a description: "GitHub Actions - Satisfactory Server"
4. Under **Scopes**, select:
   - `devices:write` (to connect to Tailscale)
5. Click **Generate client**
6. Copy the **Client ID** and **Client secret** (you'll need these for GitHub secrets)

## Step 2: Get Your Server's Tailscale IP

On your DarterPro server:

```bash
tailscale ip -4
```

This will output something like `100.x.x.x` - save this for the next step.

## Step 3: Set Up GitHub Repository Secrets

Go to your GitHub repository:
1. Navigate to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret** and add the following:

### Required Secrets

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `TS_OAUTH_CLIENT_ID` | From Step 1 | Tailscale OAuth Client ID |
| `TS_OAUTH_SECRET` | From Step 1 | Tailscale OAuth Client Secret |
| `SERVER_TAILSCALE_IP` | From Step 2 | Your server's Tailscale IP (e.g., `100.x.x.x`) |
| `SERVER_USER` | `msduncan82` | Your SSH username on the server |
| `SSH_PRIVATE_KEY` | Your private key | The SSH private key for authentication |

### Getting Your SSH Private Key

If you're using your deploy key:

**On Windows (PowerShell):**
```powershell
Get-Content C:\Users\msdun\.ssh\darterpro_deploy
```

**On Linux/WSL:**
```bash
cat ~/.ssh/darterpro_deploy
```

Copy the **entire output** including the `-----BEGIN` and `-----END` lines.

Alternatively, if you want to use a different key:

```bash
# Generate a new key specifically for GitHub Actions
ssh-keygen -t ed25519 -C "github-actions@satisfactory-server" -f ~/.ssh/github_actions_key

# Copy the public key to your server
ssh-copy-id -i ~/.ssh/github_actions_key.pub msduncan82@100.x.x.x

# Display the private key to copy to GitHub secrets
cat ~/.ssh/github_actions_key
```

## Step 4: Test the Workflow

### Manual Test

1. Go to your GitHub repository
2. Navigate to **Actions** tab
3. Select **Deploy to DarterPro** workflow
4. Click **Run workflow** → **Run workflow**
5. Watch the logs to ensure it completes successfully

### Automatic Test

Make a small change and push:

```bash
cd ~/Projects/satisfactory-server
echo "# Test deployment" >> README.md
git add README.md
git commit -m "Test GitHub Actions deployment"
git push origin main
```

Go to the **Actions** tab in GitHub to watch the deployment.

## Step 5: Verify on Server

SSH into your server and verify the changes were pulled:

```bash
ssh msduncan82@100.x.x.x
cd ~/Projects/satisfactory-server
git log -1
```

You should see your latest commit.

## Workflow Details

The workflow (`.github/workflows/deploy.yml`) does the following:

```yaml
1. Connects to Tailscale using OAuth credentials
2. SSHs into your server via Tailscale IP
3. Navigates to ~/Projects/satisfactory-server
4. Pulls latest changes from main branch
```

## Customizing the Deployment

You can modify `.github/workflows/deploy.yml` to add additional deployment steps:

```yaml
script: |
  cd ~/Projects/satisfactory-server
  git pull origin main
  
  # Example: Restart systemd service if config changed
  if git diff HEAD@{1} --name-only | grep -q "some-config-file"; then
    sudo systemctl restart satisfactory
  fi
  
  # Example: Run a deployment script
  chmod +x deploy-script.sh
  ./deploy-script.sh
  
  echo "✅ Deployment complete"
```

## Troubleshooting

### Workflow Fails: "Permission denied (publickey)"

- Verify `SSH_PRIVATE_KEY` secret contains the full private key
- Ensure the corresponding public key is in `~/.ssh/authorized_keys` on the server
- Check that `SERVER_USER` matches your actual username

### Workflow Fails: "Could not resolve hostname"

- Verify `SERVER_TAILSCALE_IP` is correct
- Ensure Tailscale is running on your server: `tailscale status`
- Check Tailscale OAuth credentials are correct

### Workflow Fails: Tailscale Connection

- Verify `TS_OAUTH_CLIENT_ID` and `TS_OAUTH_SECRET` are correct
- Check that the OAuth client has `devices:write` scope
- Ensure the OAuth client hasn't been revoked in Tailscale admin

### Git Pull Fails: "Permission denied"

- Ensure your deploy key is set up correctly on the server
- Run `ssh -T git@github.com` on the server to test GitHub access
- Check that the repository remote is using SSH: `git remote -v`

### Check Workflow Logs

1. Go to GitHub repository → **Actions** tab
2. Click on the failed workflow run
3. Expand the failed step to see detailed logs

## Security Notes

- **OAuth Credentials**: These allow GitHub Actions to temporarily join your Tailscale network
- **SSH Key**: Store only in GitHub Secrets, never commit to the repository
- **Tailscale IP**: This is only accessible within your Tailscale network
- **Deploy Key**: Read-only access to the repository

## Alternative: Using Tailscale Auth Key (Simpler but Less Secure)

If you prefer to use `TAILSCALE_AUTHKEY` instead of OAuth:

1. Generate an auth key at [Tailscale Admin → Settings → Keys](https://login.tailscale.com/admin/settings/keys)
2. Add it as `TAILSCALE_AUTHKEY` secret in GitHub
3. Modify the workflow:

```yaml
- name: Connect to Tailscale
  uses: tailscale/github-action@v2
  with:
    authkey: ${{ secrets.TAILSCALE_AUTHKEY }}
```

**Note**: OAuth is recommended because auth keys are reusable and harder to rotate.

## Next Steps

- Set up branch protection rules to require successful deployment before merging
- Add notifications (Slack, Discord, email) on deployment success/failure
- Create separate workflows for staging vs production deployments

---

**You're all set!** Every push to `main` will now automatically deploy to your DarterPro server.
