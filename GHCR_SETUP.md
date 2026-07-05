# GitHub Container Registry Setup

## Prerequisites

Before pushing to GitHub Container Registry (GHCR), ensure:

1. **GitHub Repository**: Your code is pushed to a GitHub repository
2. **Docker Images**: Built locally (already done via docker-compose)

## GitHub Actions Workflow

The workflow (`.github/workflows/docker-publish.yml`) automatically:
- Builds the PHP image on every push to `main`
- Pushes to GHCR with tags: `main`, git SHA, and semantic versions
- Uses GitHub's native GITHUB_TOKEN for authentication (no additional secrets needed)
- Implements layer caching for faster builds

## Setup Instructions

### 1. Enable GitHub Actions
Go to your repository → **Settings** → **Actions** → ensure Actions are enabled.

### 2. Configure GHCR Access
- GitHub Actions uses the built-in `GITHUB_TOKEN` automatically
- No manual PAT (Personal Access Token) needed
- The workflow has `packages: write` permission to push images

### 3. Push Your Code

```bash
git init
git add .
git commit -m "feat: containerize carbon tracker with database initialization"
git branch -M main
git remote add origin https://github.com/<YOUR_USERNAME>/<YOUR_REPO>.git
git push -u origin main
```

### 4. Monitor Builds

1. Go to your repository on GitHub
2. Navigate to **Actions** tab
3. Watch the workflow run in real-time
4. Once complete, images are available at:
   - `ghcr.io/<your-username>/carbon-tracker:main`
   - `ghcr.io/<your-username>/carbon-tracker:<commit-sha>`

## Using Images from GHCR

### Pull the Image

```bash
docker pull ghcr.io/<your-username>/carbon-tracker:main
```

### Run Locally (with docker-compose override)

Create `docker-compose.override.yml`:

```yaml
services:
  php:
    image: ghcr.io/<your-username>/carbon-tracker:main
    pull_policy: always
```

Then run:

```bash
docker compose up
```

### Deploy to Cloud (Kubernetes, Cloud Run, etc.)

Use the full image URL:
```
ghcr.io/<your-username>/carbon-tracker:main
```

## Image Visibility

By default, GHCR images are **private**. To make public:

1. Go to your repository → **Packages** (right sidebar)
2. Click the package → **Package settings**
3. Change visibility to **Public**

## Troubleshooting

### Workflow fails with authentication error
- Ensure `GITHUB_TOKEN` has `packages: write` permission (default in public repos)
- Check repository settings → Actions → General → Workflow permissions

### Image not found after push
- Wait 1-2 minutes for the image to be indexed
- Verify the build completed successfully in Actions tab
- Check image visibility settings

### Want to push to Docker Hub instead?

Replace the login step:
```yaml
- uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
```

Then add your Docker Hub credentials to repository secrets.

## File Structure

```
.
├── .github/workflows/docker-publish.yml   # CI/CD workflow
├── .gitignore                              # Excludes Docker artifacts
├── .dockerignore                           # Excludes files from image build
├── Dockerfile                              # PHP 8.2 + Apache
├── docker-compose.yml                      # Multi-container orchestration
├── init-db.sql                             # Database schema & seed data
├── php/                                    # PHP application
├── html/                                   # Frontend
├── css/                                    # Stylesheets
├── js/                                     # JavaScript
└── reports/                                # Generated PDF reports
```
