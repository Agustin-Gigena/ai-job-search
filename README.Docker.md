# AI Job Search - Docker Development & Deployment

## Quick Start

### Development (with n8n + API)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

Access:
- **n8n**: http://localhost:5678
- **AI Job Search API**: http://localhost:8000/docs (Swagger UI)
- **API Docs**: http://localhost:8000/redoc

### Production Deployment

```bash
# Set environment variables
cp .env.example .env
# Edit .env with your configuration

# Build and start
docker-compose -f docker-compose.prod.yml up -d --build
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose                           │
│                                                             │
│  ┌─────────────────┐     ┌─────────────────────────────┐   │
│  │      n8n        │────▶│   AI Job Search API         │   │
│  │   (workflow)    │     │   (FastAPI + Oh My Pi)      │   │
│  │   Port: 5678    │     │   Port: 8000                │   │
│  └─────────────────┘     └─────────────┬───────────────┘   │
│                                         │                   │
│  ┌─────────────────┐     ┌──────────────┴───────────┐      │
│  │   PostgreSQL    │     │   WhatsApp Gateway       │      │
│  │   (n8n state)   │     │   (whatsapp-web.js)      │      │
│  │   Port: 5432    │     │   Port: 3000             │      │
│  └─────────────────┘     └──────────────────────────┘      │
│                                                             │
│  Volumes:                                                   │
│  - n8n_data: n8n workflows & credentials                   │
│  - api_data: API profile, templates, output                │
│  - db_data: PostgreSQL database                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Services

### n8n (`n8n`)
- **Image**: `docker.n8n.io/n8nio/n8n:latest`
- **Port**: 5678
- **Purpose**: Workflow orchestration, cron triggers, state management
- **Volume**: `n8n_data` (persists workflows & credentials)

### AI Job Search API (`api`)
- **Build**: `./Dockerfile`
- **Port**: 8000
- **Purpose**: Job scraping, fit evaluation, CV generation
- **Volume**: `api_data` (profile.md, templates, output PDFs)

### WhatsApp Gateway (`whatsapp`)
- **Build**: `./whatsapp-gateway/Dockerfile`
- **Port**: 3000
- **Purpose**: WhatsApp Web automation (send/receive messages)
- **Note**: Optional, can use external WhatsApp service

### PostgreSQL (`db`)
- **Image**: `postgres:15-alpine`
- **Port**: 5432 (internal only)
- **Purpose**: n8n database backend
- **Volume**: `db_data`

---

## Configuration

### Environment Variables (.env)

```bash
# n8n Configuration
N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_USER_EMAIL=admin@example.com
N8N_USER_PASSWORD=changeme
WEBHOOK_URL=http://localhost:5678/

# AI Job Search API
API_HOST=0.0.0.0
API_PORT=8000
PROFILE_PATH=/app/data/structures/perfil.md
OUTPUT_PATH=/app/output
LOG_LEVEL=INFO

# WhatsApp (if using external service)
WHATSAPP_API_URL=http://whatsapp:3000
WHATSAPP_WEBHOOK_SECRET=your-secret-here

# Email (for sending CVs)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# Storage (optional - Google Drive, S3, etc.)
STORAGE_PROVIDER=local  # local, s3, gdrive
S3_BUCKET=your-bucket
GDRIVE_FOLDER_ID=your-folder-id

# Oh My Pi (if using external agents)
OH_MY_PI_API_URL=http://oh-my-pi:8080
```

---

## Development Workflow

### 1. First Time Setup

```bash
# Clone and enter repo
git clone <repo-url>
cd ai-job-search

# Copy environment
cp .env.example .env

# Start services
docker-compose up -d

# Check logs
docker-compose logs -f api
```

### 2. Developing the API

```bash
# Edit code locally
vim commands/aplicar.py

# Hot reload is enabled - API auto-restarts
# View logs in real-time
docker-compose logs -f api
```

### 3. Developing n8n Workflows

1. Open http://localhost:5678
2. Create/edit workflows using the HTTP nodes
3. Test with the API endpoints
4. Export workflows to `n8n/workflows/` for version control

### 4. Testing

```bash
# Run API tests
docker-compose exec api pytest

# Run linting
docker-compose exec api ruff check .

# Test a specific endpoint
curl -X POST http://localhost:8000/scrape \
  -H "Content-Type: application/json" \
  -d '{"queries": ["Python Developer"], "threshold": 70}'
```

---

## Production Considerations

### Security

- Change default passwords in `.env`
- Use HTTPS with a reverse proxy (nginx, traefik)
- Set `N8N_USER_PASSWORD` to a strong password
- Restrict API access with authentication tokens

### Scaling

- Use Docker Swarm or Kubernetes for multi-container orchestration
- Separate n8n and API into different hosts if needed
- Use managed PostgreSQL (RDS, Cloud SQL) instead of local volume

### Monitoring

```yaml
# Add to docker-compose.prod.yml
services:
  api:
    environment:
      - LOG_LEVEL=INFO
      - METRICS_ENABLED=true
    ports:
      - "8000:8000"
      - "9090:9090"  # Prometheus metrics
```

### Backups

```bash
# Backup n8n data
docker run --rm -v n8n_data:/data -v $(pwd):/backup ubuntu tar czf /backup/n8n-backup.tar.gz -C /data .

# Backup API data
docker run --rm -v api_data:/data -v $(pwd):/backup ubuntu tar czf /backup/api-backup.tar.gz -C /data .

# Backup database
docker-compose exec db pg_dump -U n8n n8n > db-backup.sql
```

---

## Troubleshooting

### API not starting

```bash
# Check logs
docker-compose logs api

# Rebuild
docker-compose build api
docker-compose up -d api
```

### n8n workflows not persisting

```bash
# Ensure volume is mounted correctly
docker volume inspect ai-job-search_n8n_data

# Check permissions
docker-compose exec n8n ls -la /home/node/.n8n
```

### WhatsApp not connecting

```bash
# Check WhatsApp gateway logs
docker-compose logs whatsapp

# Re-scan QR code (if using whatsapp-web.js)
docker-compose restart whatsapp
```

### LaTeX compilation errors

```bash
# Enter API container
docker-compose exec api bash

# Test compile manually
cd /app/output
lualatex -interaction=nonstopmode main_example.tex
```

---

## File Structure

```
ai-job-search/
├── .devcontainer/
│   ├── devcontainer.json       # VS Code devcontainer config
│   └── post-create.sh          # Setup script
├── docker-compose.yml          # Development compose file
├── docker-compose.prod.yml     # Production compose file
├── Dockerfile                  # API Docker image
├── .env.example                # Environment template
├── commands/                   # API CLI commands
│   ├── aplicar.py
│   ├── scrape.py
│   ├── setup.py
│   └── ...
├── skills/                     # Oh My Pi skills
│   ├── idioma-detector/
│   ├── traductor/
│   └── ...
├── plantillas/                 # LaTeX templates
│   ├── cv/
│   └── cover/
├── data/
│   └── structures/
│       └── perfil.md           # Candidate profile (English)
├── output/                     # Generated CVs/covers
├── whatsapp-gateway/           # WhatsApp service
│   ├── Dockerfile
│   └── app.js
└── n8n/
    └── workflows/              # Exported n8n workflows
        └── job-search-workflow.json
```

---

## License

MIT - See LICENSE file