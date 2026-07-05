# Copy-Paste Commands

Replace `YOUR_USERNAME` with your actual GitHub username in all commands below.

## Push to GitHub

```bash
cd ~/IdeaProjects/carbon_tracker
git init
git add .
git commit -m "Initial commit: containerized carbon tracker"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/carbon-tracker.git
git push -u origin main
```

## Pull and Run from GHCR

### Using docker-compose (Recommended)

```bash
# Create production compose file
cat > docker-compose.prod.yml << 'EOF'
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
EOF

# Start services
docker compose -f docker-compose.prod.yml up -d
```

### Using docker run

```bash
# Start MySQL
docker run -d \
  --name carbon-tracker-db \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=carbon_tracker \
  -v mysql_data:/var/lib/mysql \
  -v ./init-db.sql:/docker-entrypoint-initdb.d/01-init.sql \
  -p 3306:3306 \
  mysql:8.0

# Wait 15 seconds for MySQL to start
sleep 15

# Start app
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

## Test the Application

```bash
# Check containers are running
docker compose ps

# Homepage
curl http://localhost/html/first_page.html

# Query materials
curl http://localhost/php/db_requests.php?request=raw_material

# Query processes
curl http://localhost/php/db_requests.php?request=process

# Query countries
curl http://localhost/php/db_requests.php?request=electricity

# Query transport modes
curl http://localhost/php/db_requests.php?request=trip
```

## Check Database

```bash
# List all tables
docker exec carbon-tracker-db mysql -uroot -prootpassword carbon_tracker -e "SHOW TABLES;"

# Count records in each table
docker exec carbon-tracker-db mysql -uroot -prootpassword carbon_tracker -e \
  "SELECT COUNT(*) as materials FROM raw_materials; \
   SELECT COUNT(*) as processes FROM manufacturing_process; \
   SELECT COUNT(*) as countries FROM country_elec_ce; \
   SELECT COUNT(*) as transport FROM transport_modes;"

# Query specific data
docker exec carbon-tracker-db mysql -uroot -prootpassword carbon_tracker -e \
  "SELECT material_name, emission FROM raw_materials LIMIT 5;"
```

## View Logs

```bash
# App logs
docker compose logs app

# Database logs
docker compose logs mysql

# Follow logs (real-time)
docker compose logs -f app

# Last 50 lines
docker compose logs --tail=50 app
```

## Stop and Clean Up

```bash
# Stop containers (keep data)
docker compose -f docker-compose.prod.yml stop

# Stop and remove containers (keep data)
docker compose -f docker-compose.prod.yml down

# Stop and remove everything (delete data)
docker compose -f docker-compose.prod.yml down -v

# Remove image
docker rmi ghcr.io/YOUR_USERNAME/carbon-tracker:main

# Remove all unused images
docker image prune -a
```

## Authenticate with GHCR (Manual Push)

```bash
# Generate GitHub PAT (Personal Access Token) at: https://github.com/settings/tokens
# Select scopes: repo, write:packages, read:packages

# Login to GHCR
echo YOUR_GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Tag image
docker tag carbon-tracker:latest ghcr.io/YOUR_USERNAME/carbon-tracker:v1.0.0

# Push image
docker push ghcr.io/YOUR_USERNAME/carbon-tracker:v1.0.0

# Logout
docker logout ghcr.io
```

## Update Image on GHCR

```bash
# Make changes to your code
nano php/db_requests.php

# Commit and push (GitHub Actions builds automatically)
git add .
git commit -m "Fix: update database query logic"
git push origin main

# Wait 3-5 minutes, then pull new image
docker pull ghcr.io/YOUR_USERNAME/carbon-tracker:main

# Restart containers
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d
```

## Deploy to Cloud Platforms

### Google Cloud Run

```bash
gcloud auth configure-docker ghcr.io

gcloud run deploy carbon-tracker \
  --image ghcr.io/YOUR_USERNAME/carbon-tracker:main \
  --platform managed \
  --region us-central1 \
  --port 80 \
  --memory 512Mi \
  --set-env-vars DB_SERVER=cloudsql-proxy,DB_NAME=carbon_tracker,DB_PASSWORD=YOUR_PASSWORD
```

### Heroku (via Container Registry)

```bash
# Install Heroku CLI first: https://devcenter.heroku.com/articles/heroku-cli

heroku login
heroku container:login

# Tag image for Heroku
docker tag ghcr.io/YOUR_USERNAME/carbon-tracker:main registry.heroku.com/YOUR_APP_NAME/web

# Push to Heroku
docker push registry.heroku.com/YOUR_APP_NAME/web

# Release
heroku container:release web -a YOUR_APP_NAME
```

### AWS ECS

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

docker tag ghcr.io/YOUR_USERNAME/carbon-tracker:main YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/carbon-tracker:main

docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/carbon-tracker:main
```

### Kubernetes

```bash
# Create secret for database
kubectl create secret generic db-secret --from-literal=password=rootpassword

# Apply deployment
kubectl apply -f deployment.yaml

# View status
kubectl get pods
kubectl get services

# View logs
kubectl logs -f deployment/carbon-tracker

# Scale replicas
kubectl scale deployment carbon-tracker --replicas=3
```

## Environment Variables Reference

| Variable | Default | Purpose |
|----------|---------|---------|
| `DB_SERVER` | localhost | MySQL host |
| `DB_NAME` | carbon_tracker | Database name |
| `DB_USER` | root | Database user |
| `DB_PASSWORD` | rootpassword | Database password |

## View GitHub Actions Results

```bash
# Check workflow status online
https://github.com/YOUR_USERNAME/carbon-tracker/actions

# Watch build in real-time (if using GitHub CLI)
gh run list -R YOUR_USERNAME/carbon-tracker
gh run view --web -R YOUR_USERNAME/carbon-tracker
```

---

**Tips:**
- Always replace `YOUR_USERNAME` with your actual GitHub username
- For production, use strong passwords instead of `rootpassword`
- Store secrets in `.env` file (added to `.gitignore`)
- Don't commit sensitive data to GitHub

