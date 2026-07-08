# AI Job Search - Plan de Implementación

**Fecha:** 2026-07-08  
**Estado:** Aprobado para implementación  
**Arquitectura:** n8n + Docker + OH My Pi agents  
**Idiomas:** Perfil en inglés, output multi-idioma, interfaz es/en

---

## Resumen del Proyecto

Transformar AI Job Search de CLI interactivo a servicio automatizado:
- **n8n**: Orquestación de workflows + estado
- **FastAPI**: API REST para scrape/apply
- **Docker**: Deploy en servidor
- **WhatsApp**: Aprobaciones vía whatsapp-web.js
- **OH My Pi**: Agentes AI para evaluación y redacción

---

## Fases de Implementación

### Fase 1: Infraestructura Docker (Día 1-2)
**Objetivo:** Tener el entorno Docker funcionando con todos los servicios básicos.

#### Tareas:

1. **Crear `main.py` con FastAPI skeleton**
   - Estructura base con endpoints (/health, /scrape, /approve, /status)
   - Configurar CORS, logging, error handling
   - Health check endpoint para Docker
   - **Criterios Aceptación:**
     - `docker-compose up` levanta la API
     - GET /health retorna `{"status": "healthy"}`
     - Logs en formato JSON
   - **Estimado:** 4 horas

2. **Crear estructura `commands/`**
   - `commands/__init__.py`
   - `commands/scrape.py` - job scraping logic
   - `commands/apply.py` - aplicación a jobs
   - `commands/setup.py` - configuración inicial
   - **Criterios Aceptación:**
     - Cada comando es ejecutable independientemente
     - Tests unitarios básicos pasan
   - **Estimado:** 6 horas

3. **Configurar servicios Docker**
   - Completar `Dockerfile` con todas las dependencias
   - Ajustar `docker-compose.yml` para desarrollo
   - Crear red Docker para comunicación entre servicios
   - **Criterios Aceptación:**
     - `docker-compose up` levanta: API, n8n, DB
     - Servicios tienen health checks funcionales
     - Volúmenes persisten datos correctamente
   - **Estimado:** 3 horas

4. **Configurar WhatsApp gateway**
   - Completar `whatsapp-gateway/app.js`
   - QR code scanning y session persistence
   - Webhook a n8n
   - **Criterios Aceptación:**
     - WhatsApp gateway se conecta
     - Envía/recibe mensajes de prueba
     - Session se guarda en volumen Docker
   - **Estimado:** 5 horas

**Entregables Fase 1:**
- [ ] API Docker container funcional
- [ ] n8n container funcional
- [ ] PostgreSQL container funcional
- [ ] WhatsApp gateway funcional (opcional)
- [ ] Documentación README.Docker.md actualizada

---

### Fase 2: Core API (Día 3-5)
**Objetivo:** Implementar endpoints principales con lógica de negocio.

#### Tareas:

5. **Endpoint POST /scrape**
   - Recibir queries, portales, threshold, ubicaciones
   - Fetch jobs de portales (Playwright/httpx)
   - Retornar jobs con fit score preliminar
   - **Criterios Aceptación:**
     - Endpoint acepta JSON con queries/portales/threshold
     - Retorna lista de_jobs con id, title, company, url, fit_score
     - Jobs filtrados por threshold
     - Session_id generado para tracking
   - **Estimado:** 8 horas

6. **Endpoint POST /approve**
   - Recibir approved_jobs list
   - Trigger generation de CVs/cartas
   - Configurar storage (email/Drive/S3)
   - **Criterios Aceptación:**
     - Endpoint recibe session_id + approved_jobs
     - Procesa cada job aprobado
     - Retorna URLs de documentos generados
   - **Estimado:** 6 horas

7. **Endpoint GET /status/{session_id}**
   - Consultar estado de sesión
   - Retornar jobs_count, approved_count, applied_count
   - **Criterios Aceptación:**
     - Retorna JSON con estado completo de sesión
     - Maneja session_id inválido (404)
   - **Estimado:** 2 horas

8. **Configuración y settings**
   - `settings.py` con pydantic-settings
   - Leer .env variables
   - Validación de configuración
   - **Criterios Aceptación:**
     - Todos los settings desde .env
     - Validación de required fields
     - Defaults razonables para opcionales
   - **Estimado:** 3 horas

**Entregables Fase 2:**
- [ ] /scrape endpoint funcional
- [ ] /approve endpoint funcional
- [ ] /status endpoint funcional
- [ ] Settings management configurado
- [ ] Tests de integração para endpoints

---

### Fase 3: Skills OH My Pi (Día 6-8)
**Objetivo:** Implementar skills para detección de idioma, traducción y localización.

#### Tareas:

9. **Skill: idioma-detector**
   - `skills/idioma-detector/SKILL.md`
   - `skills/idioma-detector/detector.py`
   - Analiza posting y detecta idioma, región, formalidad
   - **Criterios Aceptación:**
     - Detecta español vs inglés (90%+ accuracy)
     - Detecta región (ES/LATAM/US/UK/DK)
     - Output: `{idioma, region, formalidad, confianza}`
   - **Estimado:** 4 horas

10. **Skill: traductor**
    - `skills/traductor/SKILL.md`
    - `skills/traductor/traductor.py`
    - Traduce perfil inglés → idioma target
    - **Criterios Aceptación:**
      - Traduce headings de secciones
      - Traduce cargos estándar
      - Mantiene skills técnicas sin traducir
      - Cache de traducciones frecuentes
    - **Estimado:** 6 horas

11. **Skill: localizador**
    - `skills/localizador/SKILL.md`
    - `skills/localizador/localizador.py`
    - Adapta formato, tono, convenciones regionales
    - **Criterios Aceptación:**
      - Formato de fecha por región
      - Saludo/cierre apropiado
      - Tono (formal/casual/tech)
    - **Estimado:** 4 horas

12. **Skill: job-evaluation**
    - `skills/job-evaluation/SKILL.md`
    - `skills/job-evaluation/evaluator.py`
    - Evalúa fit entre perfil y posting
    - **Criterios Aceptación:**
      - Score 0-100
      - Lista fortalezas (3-5)
      - Lista gaps (3-5)
      - Recomendación (proceed/no-proceed)
    - **Estimado:** 6 horas

**Entregables Fase 3:**
- [ ] idioma-detector funcional
- [ ] traductor funcional
- [ ] localizador funcional
- [ ] job-evaluation funcional
- [ ] Tests para cada skill

---

### Fase 4: Agentes OH My Pi (Día 9-11)
**Objetivo:** Implementar agentes para generación de documentos.

#### Tareas:

13. **Agente: evaluador**
    - `.omp/agents/evaluador/AGENT.md`
    - Evalúa fit posting vs perfil
    - **Criterios Aceptación:**
      - Retorna score detallado
      - Explica reasoning
      - Identifica deal-breakers
    - **Estimado:** 4 horas

14. **Agente: redactor**
    - `.omp/agents/redactor/AGENT.md`
    - Genera CV.tex + Cover.tex en idioma target
    - **Criterios Aceptación:**
      - CV sigue plantilla moderncv
      - Carta sigue plantilla cover.cls
      - Todo en idioma del posting
      - No inventa skills/experiencia
    - **Estimado:** 8 horas

15. **Agente: revisor**
    - `.omp/agents/revisor/AGENT.md`
    - Critica drafts, verifica claims
    - **Criterios Aceptación:**
      - Verifica factual accuracy
      - Revisa keywords del posting
      - Sugiere mejoras concretas
    - **Estimado:** 5 horas

16. **Integración de agentes**
    - Conectar agentes en el flujo de /approve
    - Parallel execution con task batch
    - **Criterios Aceptación:**
      - flujo completo: evaluador → redactor → revisor → redactor (revisa)
      - Output: CV.tex + Cover.tex listo para compile
    - **Estimado:** 6 horas

**Entregables Fase 4:**
- [ ] evaluador agent funcional
- [ ] redactor agent funcional
- [ ] revisor agent funcional
- [ ] Integración completa en API

---

### Fase 5: Plantillas y Compilación (Día 12-14)
**Objetivo:** Sistema de plantillas multi-idioma y compilación LaTeX.

#### Tareas:

17. **Plantillas CV multi-idioma**
    - `plantillas/cv/moderncv-base.tex` (estructura común)
    - `plantillas/cv/headers-es.tex`
    - `plantillas/cv/headers-en.tex`
    - `plantillas/cv/headers-de.tex`
    - `plantillas/cv/headers-fr.tex`
    - **Criterios Aceptación:**
      - Placeholders para headings: SECTION_EXPERIENCE
      - Headers inyectados según idioma
      - Compila en todos los idiomas
    - **Estimado:** 6 horas

18. **Plantillas Carta multi-idioma**
    - `plantillas/cover/cover-base.cls`
    - `plantillas/cover/headers-*.tex` (mismo patrón)
    - **Criterios Aceptación:**
      - Saludo/cierre localizado
      - Formato de fecha localizado
      - Compila con xelatex
    - **Estimado:** 4 horas

19. **LaTeX compile service**
    - `services/latex_compiler.py`
    - lualatex para CV, xelatex para carta
    - Verificación de páginas (2 págs CV, 1 pág carta)
    - **Criterios Aceptación:**
      - Compila automáticamente
      - Detecta errores de compilación
      - Verifica layout (no orphans)
      - Re-intenta con fixes si needed
    - **Estimado:** 8 horas

20. **ATS verification**
    - `services/ats_checker.py`
    - pdftotext extraction
    - Verifica text layer
    - **Criterios Aceptación:**
      - Extrae texto de PDF
      - Verifica email/tel como texto literal
      - Score keyword coverage
      - Graceful degradation si pdftotext no disponible
    - **Estimado:** 4 horas

**Entregables Fase 5:**
- [ ] Plantillas CV en 4 idiomas mínimo
- [ ] Plantillas Cover en 4 idiomas mínimo
- [ ] LaTeX compile service funcional
- [ ] ATS checker funcional
- [ ] Verificación de layout automática

---

### Fase 6: Integración n8n y Testing (Día 15-18)
**Objetivo:** Workflows n8n y testing end-to-end.

#### Tareas:

21. **n8n workflow principal**
    - `n8n/workflows/job-search-workflow.json`
    - Cron trigger → /scrape → WhatsApp → Wait → /approve → Email
    - **Criterios Aceptación:**
      - Cron ejecuta cada 6 horas (configurable)
      - HTTP Request nodes configurados
      - Function nodes para parsing
      - WhatsApp node integrado
      - Email node con adjuntos
    - **Estimado:** 8 horas

22. **n8n webhook handler**
    - `n8n/workflows/whatsapp-webhook.json`
    - Recibe respuestas de WhatsApp
    - Parsea "1 SI, 2 NO..."
    - Dispara /approve
    - **Criterios Aceptación:**
      - Webhook /webhook/whatsapp funcional
      - Parsea response correctamente
      - Maneja timeouts (48h)
    - **Estimado:** 5 horas

23. **Storage backends**
    - `services/storage/local.py`
    - `services/storage/email.py`
    - `services/storage/gdrive.py`
    - `services/storage/s3.py`
    - **Criterios Aceptación:**
      - Cada backend implementa interfaz común
      - Configuración vía .env
      - Tests de integración por backend
    - **Estimado:** 10 horas

24. **Testing end-to-end**
    - Test con postings reales en múltiples idiomas
    - Test WhatsApp flow completo
    - Test compilación PDFs
    - Test storage backends
    - **Criterios Aceptación:**
      - 10+ jobs procesados exitosamente
      - PDFs generados en 2+ idiomas
      - Emails enviados correctamente
      - WhatsApp responses parseadas
    - **Estimado:** 12 horas

25. **Documentación final**
    - Actualizar README.Docker.md
    - Crear ejemplos de .env
    - Troubleshooting guide
    - API docs (Swagger/OpenAPI)
    - **Criterios Aceptación:**
      - README con quickstart completo
      - .env.example comentado
      - Swagger UI en /docs accesible
    - **Estimado:** 6 horas

**Entregables Fase 6:**
- [ ] n8n workflow principal exportado
- [ ] n8n webhook handler exportado
- [ ] Storage backends funcionales
- [ ] Tests end-to-end passing
- [ ] Documentación completa

---

## Dependencias entre Tareas

```
Fase 1 (Infraestructura)
├─ 1. main.py skeleton
├─ 2. commands/ estructura
├─ 3. Docker services
└─ 4. WhatsApp gateway

         ↓

Fase 2 (Core API)
├─ 5. POST /scrape
├─ 6. POST /approve
├─ 7. GET /status
└─ 8. Settings

         ↓

Fase 3 (Skills)
├─ 9. idioma-detector
├─ 10. traductor
├─ 11. localizador
└─ 12. job-evaluation

         ↓

Fase 4 (Agentes)
├─ 13. evaluador
├─ 14. redactor
├─ 15. revisor
└─ 16. Integración

         ↓

Fase 5 (Plantillas)
├─ 17. CV templates
├─ 18. Cover templates
├─ 19. LaTeX compile
└─ 20. ATS check

         ↓

Fase 6 (Integración)
├─ 21. n8n workflow
├─ 22. n8n webhook
├─ 23. Storage backends
├─ 24. Testing E2E
└─ 25. Documentación
```

---

## Cronograma Estimado

| Fase | Días | Total Acumulado |
|------|------|-----------------|
| Fase 1: Infraestructura | 2 | Día 2 |
| Fase 2: Core API | 3 | Día 5 |
| Fase 3: Skills | 3 | Día 8 |
| Fase 4: Agentes | 3 | Día 11 |
| Fase 5: Plantillas | 3 | Día 14 |
| Fase 6: Integración | 4 | Día 18 |

**Total estimado:** 18 días laborables (~3.5 semanas)

---

## Recursos Necesarios

### Humanos
- 1 desarrollador full-stack (Python + Node.js + Docker)
- 1 revisor QA (testing end-to-end)

### Infraestructura
- Servidor con Docker (mínimo 4GB RAM, 2 CPU)
- Dominio para HTTPS (producción)
- Cuenta WhatsApp (para testing)
- SMTP server o Gmail app password

### Servicios Externos
- n8n.cloud (opcional, si no self-host)
- Google Drive API credentials (si usar GDrive)
- AWS S3 (si usar S3)
- Sentry (opcional, error tracking)

---

## Riesgos y Mitigación

| Riesgo | Impacto | Probabilidad | Mitigación |
|--------|---------|--------------|------------|
| whatsapp-web.js inestable | Alto | Media | Tener fallback a email/SMS |
| LaTeX compile errors | Medio | Alta | Test compile extensivo, fixes automáticos |
| Job portales bloquean scraping | Alto | Media | Rate limiting, rotación de user-agents, APIs oficiales si disponibles |
| Traducciones incorrectas | Medio | Media | Revisión humana inicial, cache de traducciones validadas |
| n8n workflow falla | Alto | Baja | Logs detallados, retry logic, alertas |

---

## Criterios de Éxito del Proyecto

1. **Automatización completa:**
   - [ ] Sistema corre sin intervención manual por 1 semana
   - [ ] 90%+ de jobs procesados sin errores

2. **Calidad de output:**
   - [ ] CVs en idioma correcto del posting
   - [ ] Layout de PDFs verificado (2 págs CV, 1 pág carta)
   - [ ] ATS check passing

3. **WhatsApp functional:**
   - [ ] Mensajes enviados correctamente
   - [ ] Responses parseadas correctamente
   - [ ] Session persistente entre restarts

4. **Deploy exitoso:**
   - [ ] Docker compose up sin errores
   - [ ] Health checks passing
   - [ ] Logs accesibles

5. **Documentación:**
   - [ ] README con quickstart
   - [ ] API docs en /docs
   - [ ] Troubleshooting guide

---

## Apéndice: Comandos Útiles

### Desarrollo

```bash
# Start todos los servicios
docker-compose up -d

# View logs
docker-compose logs -f api
docker-compose logs -f n8n
docker-compose logs -f whatsapp

# Enter API container
docker-compose exec api bash

# Run tests
docker-compose exec api pytest

# Rebuild after changes
docker-compose build api
docker-compose up -d api
```

### Producción

```bash
# Start production stack
docker-compose -f docker-compose.prod.yml up -d --build

# Scale API workers
docker-compose -f docker-compose.prod.yml up -d --scale api=3

# Backup database
docker-compose exec db pg_dump -U n8n n8n > backup.sql

# View production logs
docker-compose -f docker-compose.prod.yml logs -f
```

### Testing

```bash
# Test /scrape endpoint
curl -X POST http://localhost:8000/scrape \
  -H "Content-Type: application/json" \
  -d '{"queries": ["Python Developer"], "threshold": 70}'

# Test /health
curl http://localhost:8000/health

# Test WhatsApp gateway
curl -X POST http://localhost:3000/send \
  -H "Content-Type: application/json" \
  -d '{"to": "34600000000", "message": "Test message"}'
```

---

**Fin del plan de implementación**