# GitHub Authorization Fix - Scope Issues

## Problem: Can't Find "repo" Checkbox in GitHub Settings

If you're getting permission errors when GitHub Actions tries to push to GHCR, it's likely a Personal Access Token (PAT) scope issue.

---

## Solution 1: Use Built-in GITHUB_TOKEN (Easiest) ✅ RECOMMENDED

GitHub Actions has a **built-in token** that works automatically. No setup needed!

Your workflow (`.github/workflows/docker-publish.yml`) already uses it:

```yaml
- uses: docker/login-action@v3
  with:
    registry: ${{ env.REGISTRY }}
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}  # ← This is automatic!
```

**This should work without any configuration.**

### If it's still not working:

1. Go to your repository
2. Click **Settings** (top menu)
3. Scroll down to **Actions** (left sidebar)
4. Click **General**
5. Scroll to **Workflow permissions**
6. Make sure **"Read and write permissions"** is selected
7. Click **Save**

Then push again:
```bash
git push origin main
```

---

## Solution 2: Manual GitHub PAT (If Built-in Token Doesn't Work)

If the built-in token fails, create a Personal Access Token manually:

### Step 1: Create PAT

1. Go to: https://github.com/settings/tokens
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Give it a name: `GHCR_PUSH_TOKEN`
4. Set expiration: **90 days** (or longer)
5. **Select scopes:**
   - ✅ `write:packages` (push to GHCR)
   - ✅ `read:packages` (pull from GHCR)
   - ✅ `repo` (access repository)

### Step 2: Find the "repo" Checkbox

If you don't see `repo`:

**Option A: Scroll down**
- The checkboxes have many options
- Scroll down under "Scopes" section
- Look for "repo" with description "Full control of private repositories"

**Option B: Search in page**
- Press `Ctrl+F` (or `Cmd+F` on Mac)
- Type "repo"
- It will highlight the checkbox

**Option C: Use Classic token type**
- Make sure you're on "Generate new token (classic)"
- Not "Generate new token (beta)"
- Classic version has all scopes including `repo`

**Option D: If "repo" still missing**

You might be on the wrong page. Go here exactly:
https://github.com/settings/tokens/new?scopes=write:packages,read:packages,repo

This URL pre-selects the right scopes.

### Step 3: Copy and Save Token

1. Copy the token (starts with `ghp_`)
2. **DO NOT** share this or commit to git
3. Save it somewhere safe (you can only see it once)

### Step 4: Add Token to GitHub

1. Go to your repository: https://github.com/YOUR_USERNAME/carbon-tracker
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Name: `GHCR_TOKEN`
5. Value: Paste your token
6. Click **"Add secret"**

### Step 5: Update Workflow

Edit `.github/workflows/docker-publish.yml`:

Find this section:
```yaml
- name: Log in to GitHub Container Registry
  if: github.event_name != 'pull_request'
  uses: docker/login-action@v3
  with:
    registry: ${{ env.REGISTRY }}
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

Replace with:
```yaml
- name: Log in to GitHub Container Registry
  if: github.event_name != 'pull_request'
  uses: docker/login-action@v3
  with:
    registry: ${{ env.REGISTRY }}
    username: ${{ github.actor }}
    password: ${{ secrets.GHCR_TOKEN }}
```

### Step 6: Push and Test

```bash
git add .github/workflows/docker-publish.yml
git commit -m "Fix: use GHCR_TOKEN for authentication"
git push origin main
```

Check **Actions** tab - it should now work!

---

## Troubleshooting: Still Getting Errors?

### Error: "denied: permission_denied"

```
denied: permission_denied: User cannot be authenticated with the token provided
```

**Fix:**
1. Delete old token: https://github.com/settings/tokens
2. Create new token with scopes: `write:packages`, `read:packages`, `repo`
3. Update secret in repository
4. Try again

### Error: "GHCR_TOKEN not found"

Make sure you:
1. Created the secret in **Settings → Secrets and variables → Actions**
2. Named it exactly: `GHCR_TOKEN`
3. Added it to the correct repository

Check it's there: Settings → Secrets and variables → Actions (you should see it listed)

### Error: "Workflow permissions"

Go to: **Settings → Actions → General**

Under "Workflow permissions":
- ✅ Select "Read and write permissions"
- ✅ Check "Allow GitHub Actions to create and approve pull requests"
- Click **Save**

### Error: "Token expired"

GitHub PATs expire. Create a new one:
1. Go to: https://github.com/settings/tokens
2. Click the expired token → **Delete**
3. Create new token with same scopes
4. Update secret in repository

---

## Visual Guide: Finding "repo" Checkbox

### Classic Token Page (Correct)
```
✓ admin:repo_hook
✓ delete_repo
✓ repo                    ← HERE IS "repo"
  ✓ repo:status
  ✓ repo_deployment
✓ security_events
...
```

If you see this, you're on the right page.

### If You See Different Page

You might be on the "fine-grained" token page. Switch to classic:
1. https://github.com/settings/tokens
2. Click **"Generate new token"**
3. Select **"Generate new token (classic)"** in the dropdown
4. Now you'll see "repo" checkbox

---

## Quick Fix Checklist

- [ ] Go to: https://github.com/settings/tokens
- [ ] Click **"Generate new token (classic)"**
- [ ] Name: `GHCR_PUSH_TOKEN`
- [ ] Expiration: 90 days
- [ ] Check: ✅ `write:packages`
- [ ] Check: ✅ `read:packages`
- [ ] Check: ✅ `repo`
- [ ] Copy token (starts with `ghp_`)
- [ ] Go to repository → **Settings → Secrets and variables → Actions**
- [ ] Click **"New repository secret"**
- [ ] Name: `GHCR_TOKEN`
- [ ] Paste token
- [ ] Click **"Add secret"**
- [ ] Edit workflow, change `GITHUB_TOKEN` to `GHCR_TOKEN`
- [ ] Commit and push
- [ ] Check **Actions** tab for success

---

## Alternative: Use Docker Hub Instead

If you're still having GHCR issues, use Docker Hub instead:

### 1. Create Docker Hub Account
- Go to: https://hub.docker.com
- Sign up (free)

### 2. Create Access Token
- Go to: https://hub.docker.com/settings/security
- Click **"New Access Token"**
- Name: `github-actions`
- Permissions: **Read, Write, Delete**
- Copy token

### 3. Add to GitHub Secrets
- Repository → **Settings → Secrets → Actions**
- Add `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`

### 4. Update Workflow
Edit `.github/workflows/docker-publish.yml`, replace login section:

```yaml
- name: Log in to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
```

And update image name:
```yaml
images: docker.io/${{ secrets.DOCKERHUB_USERNAME }}/carbon-tracker
```

Push and test!

---

## Still Stuck?

Try this exact flow:

```bash
# 1. Check workflow file exists
cat .github/workflows/docker-publish.yml

# 2. Verify it has GITHUB_TOKEN
grep "GITHUB_TOKEN" .github/workflows/docker-publish.yml

# 3. Check repository settings
# Go to: https://github.com/YOUR_USERNAME/carbon-tracker/settings/actions

# 4. Verify workflow permissions are "Read and write"
# Should see option selected

# 5. If using PAT, verify secret exists
# Go to: https://github.com/YOUR_USERNAME/carbon-tracker/settings/secrets/actions
```

If all these check out, push a small change:

```bash
echo "# Fix test" >> README.md
git add README.md
git commit -m "test: trigger workflow"
git push origin main
```

Watch the **Actions** tab for results.

---

## Summary

| Method | Best For | Setup Time |
|--------|----------|-----------|
| **Built-in GITHUB_TOKEN** | Most users | 2 minutes (just fix workflow permissions) |
| **GitHub PAT** | Extra security needs | 5 minutes |
| **Docker Hub** | If GHCR fails | 5 minutes |

**I recommend starting with the built-in token.**

