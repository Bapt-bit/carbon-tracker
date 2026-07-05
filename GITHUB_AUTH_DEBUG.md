# GitHub Authorization - Troubleshooting Commands

## Test Your Current Setup

Run these commands to diagnose the issue:

### 1. Check if workflow file exists

```bash
cat .github/workflows/docker-publish.yml
```

Should show your workflow. Look for `GITHUB_TOKEN` or `GHCR_TOKEN`.

### 2. Check repository settings URL

```bash
echo "Check this URL:"
echo "https://github.com/$(git config user.name)/$(git config user.email | cut -d'@' -f1)/settings/actions"
```

Or manually go to:
```
https://github.com/YOUR_USERNAME/carbon-tracker/settings/actions
```

### 3. Verify workflow permissions

Look for "Workflow permissions" section. Should show:
- ✅ "Read and write permissions" (selected)

### 4. Check if secrets exist

Go to:
```
https://github.com/YOUR_USERNAME/carbon-tracker/settings/secrets/actions
```

Should list:
- `GITHUB_TOKEN` (automatic, may not show)
- `GHCR_TOKEN` (if you created it manually)

---

## Quick Fixes by Error Message

### Error: "Permission denied"

```bash
# 1. Check workflow file
grep -n "password:" .github/workflows/docker-publish.yml

# 2. Should show one of:
# - password: ${{ secrets.GITHUB_TOKEN }}
# - password: ${{ secrets.GHCR_TOKEN }}

# 3. If using GHCR_TOKEN, verify it exists:
# Go to: https://github.com/YOUR_USERNAME/carbon-tracker/settings/secrets/actions
```

### Error: "Workflow permissions insufficient"

```bash
# Fix: Go to settings
echo "https://github.com/YOUR_USERNAME/carbon-tracker/settings/actions"

# Then:
# 1. Find "Workflow permissions"
# 2. Select "Read and write permissions"
# 3. Save
```

### Error: "Token not found"

```bash
# Verify token secret name matches workflow
# In workflow, look for: ${{ secrets.XXXX_TOKEN }}
# Then verify that XXXX_TOKEN exists in secrets

# Check workflow:
grep "secrets\." .github/workflows/docker-publish.yml

# Check secrets exist at:
# https://github.com/YOUR_USERNAME/carbon-tracker/settings/secrets/actions
```

---

## Step-by-Step Troubleshooting

### If Actions Says "Permission Denied":

```bash
# 1. Edit workflow to use built-in token
cat > .github/workflows/docker-publish.yml << 'EOF'
name: Build and Push to GitHub Container Registry

on:
  push:
    branches:
      - main

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GitHub Container Registry
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
EOF

# 2. Commit and push
git add .github/workflows/docker-publish.yml
git commit -m "Fix: use GITHUB_TOKEN with proper permissions"
git push origin main

# 3. Check Actions tab
echo "Check: https://github.com/YOUR_USERNAME/carbon-tracker/actions"
```

### If Still Failing, Use PAT:

```bash
# 1. Create PAT at:
# https://github.com/settings/tokens/new?scopes=write:packages,read:packages,repo

# 2. Copy token

# 3. Create secret via GitHub UI:
# Settings → Secrets and variables → Actions → New secret
# Name: GHCR_TOKEN
# Value: your-token-here

# 4. Update workflow:
sed -i 's/secrets.GITHUB_TOKEN/secrets.GHCR_TOKEN/g' .github/workflows/docker-publish.yml

# 5. Push:
git add .github/workflows/docker-publish.yml
git commit -m "Fix: use GHCR_TOKEN"
git push origin main
```

---

## Verify Fix Works

```bash
# 1. Make a small change
echo "# Test" >> README.md

# 2. Commit and push
git add README.md
git commit -m "test: trigger workflow"
git push origin main

# 3. Open Actions
# https://github.com/YOUR_USERNAME/carbon-tracker/actions

# 4. Watch the workflow run
# Should see green ✓ when complete

# 5. Verify image was pushed
# https://github.com/YOUR_USERNAME/carbon-tracker/pkgs/container/carbon-tracker
```

---

## Check Workflow Logs

If workflow fails:

```bash
# 1. Go to Actions tab
# https://github.com/YOUR_USERNAME/carbon-tracker/actions

# 2. Click the failed workflow run

# 3. Click "Build and push" step

# 4. Expand error message
# Look for details about permission or authentication failure

# Common error locations:
# - "Log in to GitHub Container Registry" step
# - "Build and push" step
```

---

## Minimal Test Workflow

If everything else fails, test with this minimal workflow:

```bash
cat > .github/workflows/test.yml << 'EOF'
name: Test Auth

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      packages: write
    steps:
      - run: echo "Testing with GITHUB_TOKEN"
      - run: echo "Token is: ${{ secrets.GITHUB_TOKEN }}"
      - name: Login test
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - run: docker pull ghcr.io/library/hello-world
      - run: docker tag ghcr.io/library/hello-world ghcr.io/${{ github.repository_owner }}/test:latest
      - run: docker push ghcr.io/${{ github.repository_owner }}/test:latest || echo "Push failed"
EOF

git add .github/workflows/test.yml
git commit -m "test: minimal auth test"
git push origin main
```

---

## Common GitHub URLs You Need

```bash
# Workflow permissions (MOST IMPORTANT)
https://github.com/YOUR_USERNAME/carbon-tracker/settings/actions

# Secrets
https://github.com/YOUR_USERNAME/carbon-tracker/settings/secrets/actions

# Personal Access Tokens
https://github.com/settings/tokens

# Actions tab
https://github.com/YOUR_USERNAME/carbon-tracker/actions

# Image packages
https://github.com/YOUR_USERNAME/carbon-tracker/pkgs/container/carbon-tracker
```

---

## Final Debug Script

Run this to check everything:

```bash
#!/bin/bash

echo "=== GitHub Auth Debug ==="
echo ""
echo "1. Workflow file exists:"
[ -f .github/workflows/docker-publish.yml ] && echo "✓ Yes" || echo "✗ No"

echo ""
echo "2. Workflow uses correct token:"
grep -q "GITHUB_TOKEN\|GHCR_TOKEN" .github/workflows/docker-publish.yml && echo "✓ Yes" || echo "✗ No"

echo ""
echo "3. Current branch:"
git rev-parse --abbrev-ref HEAD

echo ""
echo "4. Check these URLs:"
echo "   https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/settings/actions"
echo "   https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions"

echo ""
echo "5. Next: push to trigger workflow"
echo "   git push origin main"
```

Save as `debug.sh`, then run:
```bash
chmod +x debug.sh
./debug.sh
```

---

**Need more help? Share the exact error message and I'll provide the specific fix!**

