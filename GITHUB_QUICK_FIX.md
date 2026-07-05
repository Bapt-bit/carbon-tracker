# GitHub Permission Fix - Step by Step with Pictures

## The Easiest Fix (2 minutes) ✅

### Step 1: Go to Your Repository Settings

1. Go to: `https://github.com/YOUR_USERNAME/carbon-tracker`
2. Click **Settings** (top menu, right side)

### Step 2: Find Workflow Permissions

3. On left sidebar, scroll down to **Actions** section
4. Click **General** under Actions

### Step 3: Set Permissions

5. Look for section: **Workflow permissions**
6. Select radio button: **"Read and write permissions"**
7. Check box: **"Allow GitHub Actions to create and approve pull requests"**
8. Click **Save**

**Done!** Now push your code:

```bash
git push origin main
```

Go to **Actions** tab and watch it build.

---

## If That Doesn't Work (Use Personal Access Token)

### Step 1: Create Token

Go to: https://github.com/settings/tokens

Click **"Generate new token"** dropdown

Select **"Generate new token (classic)"**

### Step 2: Fill Out Form

| Field | Value |
|-------|-------|
| **Token name** | `GHCR_PUSH_TOKEN` |
| **Expiration** | 90 days |

### Step 3: Select Scopes

**Scroll down** and check these boxes:

- ✅ `write:packages` 
- ✅ `read:packages`
- ✅ `repo` (important!)

### Step 4: Generate

Click **"Generate token"** (green button at bottom)

Copy the token (starts with `ghp_...`)

⚠️ **SAVE IT NOW** - You can only see it once!

### Step 5: Add to Repository

Go to: `https://github.com/YOUR_USERNAME/carbon-tracker`

Click **Settings** → **Secrets and variables** → **Actions**

Click **"New repository secret"**

Fill in:
```
Name: GHCR_TOKEN
Value: ghp_xxxxxxxxxxx (your token)
```

Click **"Add secret"**

### Step 6: Update Workflow

Edit file: `.github/workflows/docker-publish.yml`

Find this line:
```yaml
password: ${{ secrets.GITHUB_TOKEN }}
```

Change to:
```yaml
password: ${{ secrets.GHCR_TOKEN }}
```

Save and push:
```bash
git add .github/workflows/docker-publish.yml
git commit -m "Fix: use custom GHCR token"
git push origin main
```

**Check Actions tab - should work now!**

---

## Can't Find "repo" Checkbox?

### Try This URL

Go directly to this link:
```
https://github.com/settings/tokens/new?scopes=write:packages,read:packages,repo
```

It pre-selects the right scopes for you!

### Or Switch Token Type

Make sure you're on **"Generate new token (classic)"**

Not "Generate new token (beta)" - that's different!

---

## Final Checklist

- [ ] Went to repository Settings
- [ ] Found "Workflow permissions" section
- [ ] Selected "Read and write permissions"
- [ ] Clicked Save
- [ ] Pushed code: `git push origin main`
- [ ] Checked Actions tab
- [ ] If failed: Created Personal Access Token
- [ ] Copied token starting with `ghp_`
- [ ] Added token to repository secrets as `GHCR_TOKEN`
- [ ] Updated workflow file to use `GHCR_TOKEN`
- [ ] Pushed again
- [ ] Checked Actions tab for success ✅

---

## Quick Commands

```bash
# After saving secrets, test with:
git add .
git commit -m "Test GitHub Actions"
git push origin main

# Then watch:
# https://github.com/YOUR_USERNAME/carbon-tracker/actions
```

---

**That's it! Now your image will build and push to GHCR automatically.** 🚀

