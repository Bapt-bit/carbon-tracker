# Quick Start Guide - 5 Minutes to Production

## 🚀 Step 1: Push to GitHub (1 minute)

```bash
cd /path/to/carbon_tracker

git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/carbon-tracker.git
git push -u origin main
```

**That's it!** GitHub Actions automatically builds your Docker image.

---

## 📦 Step 2: Wait for Build (3 minutes)

1. Go to: https://github.com/YOUR_USERNAME/carbon-tracker
2. Click **Actions** tab
3. Wait for "Build and Push to GitHub Container Registry" to finish (green checkmark)

**Behind the scenes:**
- ✅ Docker image built
- ✅ Pushed to GHCR: `ghcr.io/YOUR_USERNAME/carbon-tracker:main`
- ✅ Tagged with commit SHA and branch name

---

## 🏃 Step 3: Run Locally (1 minute)

Use the pre-built image:

```bash
docker compose -f docker-compose.prod.yml up -d
```

Or manual setup:

```bash
# Create docker-compose.prod.yml (see HOW_TO_USE.md for full file)
docker compose -f docker-compose.prod.yml up -d
```

---

## ✅ Step 4: Test It Works

```bash
# Homepage
curl http://localhost/html/first_page.html

# Database query
curl http://localhost/php/db_requests.php?request=raw_material

# Check containers
docker compose ps
```

Expected output:
```
NAME                 STATUS
carbon-tracker-app   Up (healthy)
carbon-tracker-db    Up (healthy)
```

---

## 🌐 Next: Deploy Anywhere

### Option A: Keep Running on Your Machine
```bash
docker compose -f docker-compose.prod.yml up -d
# Access at http://localhost
```

### Option B: Deploy to Cloud
Replace `YOUR_USERNAME` in any of these:

**Docker Swarm:**
```bash
docker pull ghcr.io/YOUR_USERNAME/carbon-tracker:main
docker service create --name carbon-tracker -p 80:80 \
  ghcr.io/YOUR_USERNAME/carbon-tracker:main
```

**Kubernetes:**
```bash
kubectl run carbon-tracker \
  --image=ghcr.io/YOUR_USERNAME/carbon-tracker:main \
  --port=80
```

**Heroku/Railway/Render:**
- Use image URL: `ghcr.io/YOUR_USERNAME/carbon-tracker:main`
- Set env vars: `DB_SERVER`, `DB_NAME`, `DB_PASSWORD`

---

## 📝 Make Image Public (Optional)

1. Go to: https://github.com/YOUR_USERNAME/carbon-tracker/pkgs/container/carbon-tracker
2. Click **Package settings**
3. Change Visibility to **Public**

Now anyone can pull your image without authentication.

---

## 🔄 Update Your App

When you make changes:

```bash
git add .
git commit -m "Update features"
git push origin main
```

New image automatically builds and pushes with:
- Tag: `main` (always latest)
- Tag: specific commit SHA (for rollback)

Pull and run:
```bash
docker pull ghcr.io/YOUR_USERNAME/carbon-tracker:main
docker compose down && docker compose up -d
```

---

## 📚 Full Documentation

- **Detailed guide:** See `HOW_TO_USE.md`
- **GHCR setup:** See `GHCR_SETUP.md`
- **Local development:** See `PUSH_TO_GITHUB.md`

---

## 💡 Common Commands

| What | How |
|------|-----|
| View image size | `docker images ghcr.io/YOUR_USERNAME/carbon-tracker` |
| Check running containers | `docker compose ps` |
| View app logs | `docker compose logs app` |
| View database logs | `docker compose logs mysql` |
| Enter MySQL shell | `docker exec -it carbon-tracker-db mysql -uroot -prootpassword` |
| Stop everything | `docker compose down` |
| Stop & remove data | `docker compose down -v` |
| Rebuild locally | `docker build -t carbon-tracker:dev .` |

---

## ❓ Stuck?

1. **Image not found:** Wait 2 minutes for indexing, check Actions tab for build status
2. **Can't connect to DB:** Run `docker compose ps` to verify both containers started
3. **Port 80 in use:** Change to `8080:80` in docker-compose.yml
4. **Permission error:** See troubleshooting section in `HOW_TO_USE.md`

---

**You're ready! 🎉**
