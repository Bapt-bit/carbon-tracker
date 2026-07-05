# How to Use Carbon Tracker Docker Images

## Part 1: Push Code to GitHub & Build Images

### Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Enter repository name: `carbon-tracker`
3. Choose visibility: **Public** (so GHCR image can be public)
4. Click "Create repository"

### Step 2: Push Your Local Code

In your project directory:

```bash
# Initialize git (if not done)
git init

# Add all files
git add .

# Commit with a message
git commit -m "Initial commit: containerized carbon tracker with database"

# Rename branch to main
git branch -M main

# Add remote repository
git remote add origin https://github.com/YOUR_USERNAME/carbon-tracker.git

# Push to GitHub
git push -u origin main
```

Replace `YOUR_USERNAME` with your actual GitHub username.

### Step 3: GitHub Actions Builds Automatically

1. Go to your repository on GitHub
2. Click **Actions** tab at the top
3. You'll see "Build and Push to GitHub Container Registry" workflow running
4. Wait 3-5 minutes for it to complete

**What happens:**
- GitHub downloads your code
- Builds the Docker image from Dockerfile
- Pushes to GHCR at: `ghcr.io/YOUR_USERNAME/carbon-tracker:main`
- Tags with commit SHA and branch name

✅ When complete, you'll see a green checkmark

---

## Part 2: Pull and Run Images Locally

### Option A: Using docker-compose (Easiest)

Create a new `docker-compose.prod.yml` file:

```yaml
services:
  php:
    image: ghcr.io/YOUR_USERNAME/carbon-tracker:main
    pull_policy: always
    container_name: carbon-tracker-app
    ports:
      - "80:80"
    volumes:
      - ./reports:/var/www/html/reports
    environment:
      - DB_SERVER=mysql
      - DB_NAME=carbon_tracker
      - DB_USER=root
      - DB_PASSWORD=rootpassword
    depends_on:
      mysql:
        condition: service_healthy
    networks:
      - carbon-network

  mysql:
    image: mysql:8.0
    container_name: carbon-tracker-db
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: carbon_tracker
    volumes:
      - mysql_data:/var/lib/mysql
      - ./init-db.sql:/docker-entrypoint-initdb.d/01-init.sql
    ports:
      - "3306:3306"
    networks:
      - carbon-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 5s
      retries: 5

volumes:
  mysql_data:

networks:
  carbon-network:
    driver: bridge
```

Then run:

```bash
docker compose -f docker-compose.prod.yml up -d
```

### Option B: Using docker run (Manual)

Start MySQL first:

```bash
docker run -d \
  --name carbon-tracker-db \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=carbon_tracker \
  -v mysql_data:/var/lib/mysql \
  -v ./init-db.sql:/docker-entrypoint-initdb.d/01-init.sql \
  -p 3306:3306 \
  mysql:8.0
```

Wait 10 seconds, then start the app:

```bash
docker run -d \
  --name carbon-tracker-app \
  -p 80:80 \
  -e DB_SERVER=carbon-tracker-db \
  -e DB_NAME=carbon_tracker \
  -e DB_USER=root \
  -e DB_PASSWORD=rootpassword \
  --link carbon-tracker-db \
  -v ./reports:/var/www/html/reports \
  ghcr.io/YOUR_USERNAME/carbon-tracker:main
```

### Option C: Just the Dockerfile (No GHCR)

If you haven't pushed to GitHub yet:

```bash
# Build locally
docker build -t carbon-tracker:latest .

# Run with docker-compose
docker compose up -d
```

---

## Part 3: Verify It's Running

### Check containers are up:

```bash
docker compose ps
```

Should show:
```
NAME                 STATUS
carbon-tracker-app   Up (health: healthy)
carbon-tracker-db    Up (healthy)
```

### Test the application:

```bash
# Get homepage
curl http://localhost/html/first_page.html

# Query materials from database
curl http://localhost/php/db_requests.php?request=raw_material
```

Should return JSON:
```json
[
  {"material_name":"Primary Aluminum"},
  {"material_name":"Nickel"},
  ...
]
```

### Check database directly:

```bash
docker exec carbon-tracker-db mysql -uroot -prootpassword -e \
  "USE carbon_tracker; SELECT COUNT(*) as total FROM raw_materials;"
```

Should return: `27` materials

---

## Part 4: Make GHCR Image Public (Optional)

By default, images are private. To make them public:

1. Go to: https://github.com/YOUR_USERNAME/carbon-tracker
2. Click **Packages** (right sidebar)
3. Click **carbon-tracker** package
4. Click **Package settings** (gear icon)
5. Change "Visibility" to **Public**
6. Save

Now anyone can pull your image:

```bash
docker pull ghcr.io/YOUR_USERNAME/carbon-tracker:main
```

---

## Part 5: Use in Production

### Deploy to Docker Swarm:

```bash
# Initialize swarm (on manager node)
docker swarm init

# Create service
docker service create \
  --name carbon-tracker \
  --publish 80:80 \
  --replicas 3 \
  ghcr.io/YOUR_USERNAME/carbon-tracker:main
```

### Deploy to Kubernetes:

Create `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: carbon-tracker
spec:
  replicas: 3
  selector:
    matchLabels:
      app: carbon-tracker
  template:
    metadata:
      labels:
        app: carbon-tracker
    spec:
      containers:
      - name: app
        image: ghcr.io/YOUR_USERNAME/carbon-tracker:main
        ports:
        - containerPort: 80
        env:
        - name: DB_SERVER
          value: mysql
        - name: DB_NAME
          value: carbon_tracker
        - name: DB_USER
          value: root
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: carbon-tracker
spec:
  selector:
    app: carbon-tracker
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: LoadBalancer
```

Deploy:

```bash
kubectl apply -f deployment.yaml
```

### Deploy to Cloud Run (Google Cloud):

```bash
gcloud run deploy carbon-tracker \
  --image ghcr.io/YOUR_USERNAME/carbon-tracker:main \
  --platform managed \
  --region us-central1 \
  --port 80 \
  --set-env-vars DB_SERVER=cloudsql-proxy,DB_NAME=carbon_tracker
```

### Deploy to AWS ECS:

```bash
aws ecs register-task-definition \
  --family carbon-tracker \
  --container-definitions "[\
    {\
      \"name\": \"carbon-tracker\",\
      \"image\": \"ghcr.io/YOUR_USERNAME/carbon-tracker:main\",\
      \"portMappings\": [{\"containerPort\": 80}],\
      \"environment\": [\
        {\"name\": \"DB_SERVER\", \"value\": \"mysql.rds.amazonaws.com\"}\
      ]\
    }\
  ]"
```

---

## Part 6: Update Your Image

When you make changes:

1. Edit your code (PHP, HTML, CSS, etc.)
2. Commit and push:

```bash
git add .
git commit -m "Update carbon tracker features"
git push origin main
```

3. GitHub Actions automatically builds and pushes new image with:
   - Tag: `main` (latest)
   - Tag: git commit SHA (specific version)
   - Old images remain available at old commit SHAs

4. Pull the new image:

```bash
docker pull ghcr.io/YOUR_USERNAME/carbon-tracker:main
docker compose up -d
```

---

## Part 7: Troubleshooting

### Q: Permission denied when pushing to GHCR

**Error:** `denied: permission_denied: User cannot be authenticated with the token provided`

**Solution:** 
- GitHub Actions uses automatic `GITHUB_TOKEN` (no setup needed)
- If pushing manually with Docker, authenticate first:

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

### Q: Image not found after workflow completes

**Error:** `Error response from daemon: manifest not found`

**Solution:**
- Wait 2-3 minutes for image to be indexed
- Verify workflow completed (green checkmark in Actions tab)
- Check image exists: `https://github.com/YOUR_USERNAME/carbon-tracker/pkgs/container/carbon-tracker`

### Q: Container won't start - "Cannot connect to database"

**Error:** `DB connection error: Connection refused`

**Solution:**
- Make sure both containers are running: `docker compose ps`
- Wait 10-15 seconds for MySQL to be ready
- Check MySQL logs: `docker compose logs mysql`
- Verify environment variables match

### Q: Database not initialized

**Error:** `Table doesn't exist` or no data in queries

**Solution:**
- Check if init-db.sql was mounted: `docker exec carbon-tracker-db ls /docker-entrypoint-initdb.d/`
- Recreate database: `docker compose down -v` then `docker compose up -d`
- Verify data: `docker exec carbon-tracker-db mysql -uroot -prootpassword carbon_tracker -e "SHOW TABLES;"`

### Q: Port 80 already in use

**Error:** `Error starting userland proxy: Bind for 0.0.0.0:80 failed`

**Solution:**
- Change port in docker-compose.yml:
  ```yaml
  ports:
    - "8080:80"  # Changed from 80:80
  ```
- Access at: `http://localhost:8080`

---

## Quick Reference

| Task | Command |
|------|---------|
| Push code to GitHub | `git push origin main` |
| View workflows | `https://github.com/YOUR_USERNAME/carbon-tracker/actions` |
| Pull latest image | `docker pull ghcr.io/YOUR_USERNAME/carbon-tracker:main` |
| Start locally | `docker compose up -d` |
| Stop containers | `docker compose down` |
| View logs | `docker compose logs -f app` |
| Enter database | `docker exec -it carbon-tracker-db mysql -uroot -prootpassword` |
| Remove everything | `docker compose down -v` |

