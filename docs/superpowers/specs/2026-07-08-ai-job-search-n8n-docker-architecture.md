# AI Job Search - Arquitectura n8n + Docker

**Fecha:** 2026-07-08  
**Estado:** En revisión  
**Tipo:** Arquitectura serverless automatizada  
**Orquestador:** n8n  
**Deploy:** Docker Compose

---

## 1. Resumen Ejecutivo

Transformación del framework AI Job Search de **CLI interactivo** a **servicio automatizado** orquestado por n8n, con:

- **Búsqueda automática** de empleos (cron every 6-12 hours)
- **Evaluación de fit** automática con agentes AI
- **Aprobación vía WhatsApp** (whatsapp-web.js)
- **Generación de CV/carta** multi-idioma on-demand
- **Deploy en Docker** para producción

### Cambio de Paradigma

| Aspecto | Diseño Original (CLI) | Nuevo Diseño (n8n + Docker) |
|---------|----------------------|----------------------------|
| Interfaz | Terminal/chat Oh My Pi | Webhook HTTP + WhatsApp |
| Trigger | Usuario ejecuta comando | Cron job en n8n |
| Estado | Archivos `local://` | Stateless; n8n guarda estado |
| Output | Archivos locales | Email / Cloud Storage |
| Deploy | Workstation local | Servidor Docker |

---

## 2. Arquitectura del Sistema

### 2.1 Diagrama General

```
┌─────────────────────────────────────────────────────────────────┐
│                    n8n Server                                   │
│  (orquestador central)                                          │
│                                                                 │
│  ┌─────────────────┐  ┌───────────────┐  ┌─────────────────┐   │
│  │ Cron Trigger    │  │ Webhook       │  │ Estado:         │   │
│  │ (cada 6 horas)  │──▶│ /scrape +     │  │ - Jobs vistos   │   │
│  │                 │  │ /apply        │  │ - Aprobaciones   │   │
│  └─────────────────┘  └───────────────┘  │ - Aplicados     │   │
│                                          └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │ HTTP POST
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                AI Job Search API (Docker)                       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  FastAPI Server (Python)                                │   │
│  │                                                          │   │
│  │  POST /scrape  → Fetch jobs, eval fit, return list      │   │
│  │  POST /approve → Receive approvals, apply to jobs       │   │
│  │  GET  /status  → System status                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│         ┌────────────────────┼────────────────────┐            │
│         ▼                    ▼                    ▼            │
│  ┌─────────────┐   ┌─────────────────┐  ┌─────────────────┐   │
│  │ Job         │   │ AI Job          │  │ WhatsApp        │   │
│  │ Portal      │   │ Evaluator       │  │ Gateway         │   │
│  │ Fetcher     │   │ (Oh My Pi       │  │ (web hook       │   │
│  │             │   │  agents)        │  │  whatsapp-web)  │   │
│  └─────────────┘   └─────────────────┘  └─────────────────┘   │
│                              │                                  │
│         ┌────────────────────┼────────────────────┐            │
│         ▼                    ▼                    ▼            │
│  ┌─────────────┐   ┌─────────────────┐  ┌─────────────────┐   │
│  │ CV/Cover    │   │ Email /         │  │ Logs /          │   │
│  │ Letter      │   │ Cloud Storage   │  │ Auditoría       │   │
│  │ Generator   │   │ (Drive, S3)     │  │                 │   │
│  └─────────────┘   └─────────────────┘  └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Componentes Docker

```yaml
services:
  api:        # FastAPI + Oh My Pi agents + LaTeX
  n8n:        # Workflow orchestration + state
  db:         # PostgreSQL (n8n state)
  whatsapp:   # whatsapp-web.js gateway (optional)
```

---

## 3. APIs y Endpoints

### 3.1 API Endpoints (FastAPI)

#### POST /scrape

**Descripción:** Busca empleos, evalúa fit, retorna lista filtrada.

**Input:**
```json
{
  "queries": ["Python Developer", "Data Engineer"],
  "portales": ["jobindex", "linkedin"],
  "threshold": 70,
  "ubicaciones": ["Remote", "Copenhagen", "Madrid"],
  "idioma_interfaz": "es"
}
```

**Output:**
```json
{
  "session_id": "abc123",
  "jobs": [
    {
      "id": "job_001",
      "title": "Senior Python Developer",
      "company": "TechCorp A/S",
      "url": "https://jobindex.dk/job/123456",
      "fit_score": 85,
      "idioma": "en",
      "ubicacion": "Copenhagen (Hybrid)",
      "fortalezas": ["5 years Python", "ML experience"],
      "gaps": ["No Kubernetes mentioned"]
    }
  ],
  "total_encontrados": 15,
  "total_filtrados": 5
}
```

#### POST /approve

**Descripción:** Recibe aprobaciones, genera CVs, aplica a jobs.

**Input:**
```json
{
  "session_id": "abc123",
  "approved_jobs": ["job_001", "job_003"],
  "rejected_jobs": ["job_002", "job_004", "job_005"],
  "email_config": {
    "enviar_a": "usuario@email.com",
    "adjuntar_pdf": true
  },
  "storage_config": {
    "provider": "gdrive",
    "folder_id": "abc123xyz"
  }
}
```

**Output:**
```json
{
  "status": "complete",
  "applied": ["job_001", "job_003"],
  "documents": [
    {
      "job_id": "job_001",
      "cv_url": "https://drive.google.com/...",
      "cover_url": "https://drive.google.com/..."
    },
    {
      "job_id": "job_003",
      "cv_url": "https://drive.google.com/...",
      "cover_url": "https://drive.google.com/..."
    }
  ]
}
```

#### GET /status/{session_id}

**Descripción:** Consulta estado de sesión.

**Output:**
```json
{
  "session_id": "abc123",
  "state": "awaiting_approval",
  "created_at": "2024-01-15T10:30:00Z",
  "jobs_count": 5,
  "approved_count": 0,
  "applied_count": 0
}
```

#### GET /health

**Descripción:** Health check para Docker.

**Output:** `{"status": "healthy", "version": "1.0.0"}`

---

### 3.2 n8n Webhooks

#### Webhook: /webhook/whatsapp

**Descripción:** Recibe respuestas de WhatsApp.

**Input (desde whatsapp-web.js):**
```json
{
  "from": "34600000000@c.us",
  "body": "1 SI, 3 SI",
  "timestamp": 1705312200
}
```

**Procesamiento:**
1. Parsea respuesta (formato: `"1 SI, 3 NO"`)
2. Extrae job IDs aprobados/rechazados
3. Dispara `POST /approve` con lista

---

## 4. Flujo Completo

### 4.1 Workflow de n8n

```
┌─────────────────────────────────────────────────────────────┐
│ n8n Workflow: AI Job Search Automation                      │
└─────────────────────────────────────────────────────────────┘

1. Cron Trigger (0 0 */6 * * *) — cada 6 horas
   │
   ▼
2. HTTP Request: POST /scrape
   Body: { queries, portales, threshold, ubicaciones }
   │
   ▼
3. Function: Procesa respuesta
   - Extrae jobs queue pasan threshold
   - Formatea mensaje para WhatsApp
   │
   ▼
4. WhatsApp: Envía mensaje
   "🔍 Encontré 5 jobs que matchan tu perfil:
   
   1️⃣ Senior Python Dev @ TechCorp (85% fit)
      Copenhagen • Inglés
      ✅ 5 años Python  ⚠️ Sin K8s
   
   2️⃣ Data Engineer @ DataCo (78% fit)
      Madrid • Español
      ✅ SQL avanzado  ⚠️ Sin Airflow
   
   Responde: '1 SI, 2 NO, 3 SI...'
   "
   │
   ▼
5. Wait for Webhook (timeout: 48h)
   - Escucha /webhook/whatsapp
   - Parsea respuesta del usuario
   │
   ▼
6. Si hay aprobaciones:
   HTTP Request: POST /approve
   Body: { session_id, approved_jobs, email_config }
   │
   ▼
7. Email: Envía CVs generados
   Asunto: "Tus aplicaciones están listas ✅"
   Adjuntos: CVs + cartas en PDF
   │
   ▼
8. Function: Actualiza estado
   - Marca jobs como "aplicados" en n8n DB
   - Log para auditoría
```

---

## 5. WhatsApp Gateway

### 5.1 whatsapp-web.js Integration

**Ubicación:** `whatsapp-gateway/app.js`

**Características:**
- QR code scan inicial (se guarda sesión en volumen Docker)
- Envío de mensajes con formato Markdown básico
- Recepción de respuestas
- Reenvío a webhook de n8n

**Formato de mensaje:**
```
🔍 Encontré {N} jobs que matchan tu perfil:

{emoji} {title} @ {company} ({fit_score}% fit)
   {location} • {idioma}
   ✅ {fortaleza_1}  ⚠️ {gap_1}

{emoji} {title} @ {company} ...

━━━━━━━━━━━━━━━━━━━━
Responde así:
"1 SI, 2 NO, 3 SI, 4 NO..."
```

**Emojis por fit score:**
- 90-100%: 🎯
- 80-89%: ✅
- 70-79%: 👍

---

## 6. Storage & Output

### 6.1 Opciones de Storage

| Provider | Uso | Configuración |
|----------|-----|---------------|
| **Local** | Desarrollo, testing | `STORAGE_PROVIDER=local` |
| **Email** | Envío directo al usuario | `SMTP_HOST`, `SMTP_USER`, etc. |
| **Google Drive** | Almacenamiento cloud | `GDRIVE_FOLDER_ID`, credentials JSON |
| **AWS S3** | Enterprise, scalable | `S3_BUCKET`, AWS keys |

### 6.2 Estructura de Output

```
output/
├── 2026-07-08/
│   ├── job_001/
│   │   ├── cv_main_TechCorp_en.tex
│   │   ├── cv_main_TechCorp_en.pdf
│   │   ├── cover_TechCorp_en.tex
│   │   └── cover_TechCorp_en.pdf
│   ├── job_003/
│   │   └── ...
│   └── MANIFEST.json  # Metadata de la tanda
├── 2026-07-15/
│   └── ...
└── logs/
    └── applications.log
```

### 6.3 MANIFEST.json

```json
{
  "session_id": "abc123",
  "fecha": "2026-07-08T10:30:00Z",
  "jobs_aplicados": [
    {
      "job_id": "job_001",
      "title": "Senior Python Developer",
      "company": "TechCorp A/S",
      "url": "https://jobindex.dk/job/123456",
      "fit_score": 85,
      "cv_path": "output/2026-07-08/job_001/cv_main_TechCorp_en.pdf",
      "cover_path": "output/2026-07-08/job_001/cover_TechCorp_en.pdf",
      "estado": "aplicado",
      "fecha_aplicacion": "2026-07-08T11:15:00Z"
    }
  ]
}
```

---

## 7. Docker Deployment

### 7.1 Archivos de Configuración

| Archivo | Propósito |
|---------|-----------|
| `Dockerfile` | API Python + LaTeX + Bun |
| `docker-compose.yml` | Desarrollo (todos los servicios) |
| `docker-compose.prod.yml` | Producción (optimizado) |
| `.env.example` | Template de variables de entorno |
| `.dockerignore` | Excluir archivos del build |
| `.devcontainer/devcontainer.json` | VS Code remote development |

### 7.2 Volúmenes Docker

```yaml
volumes:
  n8n_data:      # Workflows y credenciales de n8n
  db_data:       # Base de datos PostgreSQL
  api_data:      # perfil.md, templates, whatsapp-session
  api_output:    # PDFs generados
  api_logs:      # Logs de la API
```

### 7.3 Comandos Útiles

```bash
# Desarrollo
docker-compose up -d
docker-compose logs -f api
docker-compose exec api bash

# Producción
docker-compose -f docker-compose.prod.yml up -d --build
docker-compose -f docker-compose.prod.yml logs -f

# WhatsApp (si se usa)
docker-compose --profile with-whatsapp up -d

# Backups
docker-compose exec db pg_dump -U n8n n8n > backup.sql
```

---

## 8. Seguridad

### 8.1 Consideraciones

- **HTTPS obligatorio** en producción (usar reverse proxy: nginx/traefik)
- **Cambio de contraseñas** por defecto (n8n admin, PostgreSQL)
- **API auth tokens** para webhooks
- **WhatsApp session** en volumen persistente (no commitear)
- **Secrets management**: Usar Docker secrets o HashiCorp Vault en producción

### 8.2 Variables Críticas (.env)

```bash
# CAMBIAR SIEMPRE
N8N_USER_PASSWORD=strong_password_here
POSTGRES_PASSWORD=another_strong_password
API_AUTH_TOKEN=generate_secure_random_token
JWT_SECRET_KEY=generate_another_secure_key
WHATSAPP_WEBHOOK_SECRET=webhook_secret_here
```

---

## 9. Monitoreo

### 9.1 Health Checks

```yaml
api:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
    interval: 15s
    timeout: 5s
    retries: 3

n8n:
  healthcheck:
    test: ["CMD-SHELL", "curl -f http://localhost:5678/health || exit 1"]
    interval: 15s
    timeout: 5s
    retries: 3
```

### 9.2 Logs

- **API**: `/app/logs/app.log` (JSON format)
- **n8n**: stdout/stderr (docker logs)
- **WhatsApp**: `/app/logs/whatsapp.log`

### 9.3 Métricas (Opcional)

```bash
# Prometheus endpoint (si METRICS_ENABLED=true)
http://localhost:9090/metrics

# Métricas clave:
- jobs_scraped_total
- jobs_applied_total
- fit_score_average
- cv_generation_duration_seconds
- whatsapp_messages_sent_total
```

---

## 10. Próximos Pasos

### Fase 1: Infraestructura Docker (Semana 1)
- [ ] `Dockerfile` multi-stage para API
- [ ] `docker-compose.yml` para desarrollo
- [ ] `docker-compose.prod.yml` para producción
- [ ] `.env.example` con todas las variables
- [ ] `whatsapp-gateway/` con whatsapp-web.js

### Fase 2: API FastAPI (Semana 2-3)
- [ ] `main.py` con endpoints (/scrape, /approve, /status)
- [ ] Integración con Oh My Pi agents (SDK o subprocess)
- [ ] LaTeX compile + PDF verification
- [ ] Storage backends (local, email, S3, GDrive)

### Fase 3: n8n Workflows (Semana 3)
- [ ] Workflow principal (cron → scrape → WhatsApp → approve → apply)
- [ ] Webhook handler para respuestas de WhatsApp
- [ ] Email node para envío de PDFs
- [ ] Funciones JavaScript para parsing/formatting

### Fase 4: WhatsApp Gateway (Semana 4)
- [ ] `whatsapp-web.js` app.js
- [ ] QR code scanning y session persistence
- [ ] Envío de mensajes con formato
- [ ] Recepción y parsing de respuestas
- [ ] Webhook a n8n

### Fase 5: Testing & QA (Semana 5)
- [ ] Test end-to-end con postings reales
- [ ] Test WhatsApp flow completo
- [ ] Test compilación PDFs multi-idioma
- [ ] Test storage backends

### Fase 6: Documentación (Semana 6)
- [ ] README.Docker.md (guía de deploy)
- [ ] n8n workflows exportados a `n8n/workflows/`
- [ ] Ejemplos de configuración .env
- [ ] Troubleshooting guide

---

**Fin del documento de arquitectura n8n + Docker**