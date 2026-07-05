# Carbon Tracker - Docker & GHCR Setup

Your project is now fully containerized and ready to push to GitHub Container Registry.

## Quick Start: Push to GitHub

### 1. Initialize Git (if not already done)

```bash
cd /path/to/carbon_tracker
git init
git add .
git commit -m "feat: containerize carbon tracker with database initialization and GHCR CI/CD"
git branch -M main
```

### 2. Create Repository on GitHub

1. Go to https://github.com/new
2. Create repository named `carbon-tracker`
3. Copy the commands shown and run:

```bash
git remote add origin https://github.com/<YOUR_USERNAME>/carbon-tracker.git
git push -u origin main
```

### 3. GitHub Actions Triggers Automatically

- Workflow watches for pushes to `main` branch
- Builds Docker image automatically
- Pushes to GHCR at: `ghcr.io/<your-username>/carbon-tracker:main`
- Check progress in **Actions** tab on GitHub

## What's Included

✓ **Dockerfile** - PHP 8.2 Apache container optimized for production  
✓ **docker-compose.yml** - PHP + MySQL orchestration with networking  
✓ **init-db.sql** - Auto-initializes database with 84 data entries  
✓ **.github/workflows/docker-publish.yml** - CI/CD pipeline to GHCR  
✓ **.gitignore** - Excludes secrets, artifacts, Docker files  
✓ **.dockerignore** - Optimizes build context  

## Local Testing (Before Push)

Verify everything works:

```bash
docker compose down -v
docker compose up -d
curl http://localhost/html/first_page.html
curl http://localhost/php/db_requests.php?request=raw_material
```

Expected: HTTP 200, JSON data from database

## Image Pull After Push

Once GHCR workflow completes:

```bash
docker pull ghcr.io/<your-username>/carbon-tracker:main
docker run -p 80:8080 ghcr.io/<your-username>/carbon-tracker:main
```

## Troubleshooting

**Q: Workflow fails?**  
A: Check Actions tab → click failed job → scroll to see error logs

**Q: Image not found after push?**  
A: Wait 2 minutes for indexing, then verify at:  
`https://github.com/<username>/carbon-tracker/pkgs/container/carbon-tracker`

**Q: Want to make image public?**  
A: Package settings → visibility → Public

## Next Steps

- Deploy to production: Kubernetes, Docker Swarm, or cloud platforms
- Add database migrations for schema updates
- Set up environment configs for staging/production
- Add health check endpoints for load balancers

---

See `GHCR_SETUP.md` for detailed instructions.
