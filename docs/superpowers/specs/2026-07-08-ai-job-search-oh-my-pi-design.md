## 1. Resumen Ejecutivo

Migración completa del framework AI Job Search desde Claude Code a Oh My Pi, con:
- **Almacenamiento del perfil en inglés** (base universal)
- **Detección automática del idioma del posting** (cualquier idioma)
- **Traducción automática del CV** desde inglés al idioma del posting
- **Interfaz configurable** en español o inglés

### Decisiones Clave

| Área | Decisión |
|------|----------|
| Perfil base | **Inglés** (almacenamiento universal) |
| Idioma de comunicación | **Español o inglés** (seleccionable por usuario) |
| Idioma de CV/carta | **Cualquier idioma** detectado en el posting (es, en, da, de, fr, pt, it, nl, etc.) |
| Traducción | Automática: inglés → idioma target (on-the-fly) |
| Enfoque de migración | Port nativo completo a Oh My Pi |
| Plantillas | Multi-idioma (estructura base + headings localizados) |

---

## 2. Arquitectura

### 2.1 Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────┐
│                    Oh My Pi Session                         │
│  (interfaz en español, todo output en español)              │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌─────────────────┐   ┌─────────────────┐
│  CLI Commands │   │  Agents         │   │  Skills         │
│  (Python)     │   │  (task batch)   │   │  (conocimiento) │
│               │   │                 │   │                 │
│  /aplicar     │   │  - Scraper      │   │  - Idioma       │
│  /setup       │   │  - Evaluador    │   │  - Perfil       │
│  /scrape      │   │  - Redactor     │   │  - Traductor    │
│  /rank        │   │  - Revisor      │   │  - Localizador  │
└───────────────┘   └─────────────────┘   └─────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌─────────────────┐   ┌─────────────────┐
│  Oh My Pi     │   │  Context        │   │  Output         │
│  Tools        │   │  Files          │   │  Artifacts      │
│               │   │                 │   │                 │
│  - agent()    │   │  - perfil.md    │   │  - CV.tex (es/en)│
│  - browser()  │   │  - contexto.md  │   │  - Cover.tex    │
│  - bash()     │   │  - plantillas/  │   │  - PDF compiled │
│  - read/write │   │  - tracker.csv  │   │  - informe.md   │
│  - task()     │   │                 │   │                 │
└───────────────┘   └─────────────────┘   └─────────────────┘
```

### 2.2 Estructura de Archivos

```
ai-job-search/
├── .omp/
│   ├── agents/
│   │   ├── evaluador/
│   │   │   └── AGENT.md         # Agente de evaluación de fit
│   │   ├── redactor/
│   │   │   └── AGENT.md         # Agente de redacción CV/carta
│   │   ├── revisor/
│   │   │   └── AGENT.md         # Agente de revisión y crítica
│   │   └── scraper/
│   │       └── AGENT.md         # Agente de búsqueda de empleos
│   └── skills/
│       ├── idioma-detector/
│       │   └── SKILL.md         # Detección es/en
│       ├── traductor/
│       │   └── SKILL.md         # Traducción es→en
│       └── localizador/
│           └── SKILL.md         # Adaptación regional
├── commands/
│   ├── aplicar.py               # /aplicar <URL>
│   ├── setup.py                 # /setup
│   ├── scrape.py                # /scrape
│   ├── rank.py                  # /rank
│   └── portales.py              # /portales
├── plantillas/
│   ├── cv/
│   │   ├── moderncv-es.tex      # CV español
│   │   └── moderncv-en.tex      # CV inglés
│   └── cover/
│       ├── cover-es.cls         # Carta español
│       └── cover-en.cls         # Carta inglés
├── local://
│   ├── perfil.md                # Perfil del candidato (español)
│   ├── contexto.md              # Configuración y preferencias
│   ├── traducciones.json        # Cache de traducciones comunes
│   └── tracker.csv              # Seguimiento de aplicaciones
├── documents/
│   ├── cv/                      # CV maestro (PDF o .tex)
│   ├── linkedin/                # Export LinkedIn
│   ├── diplomas/                # Certificados
│   └── applications/            # Historial de aplicaciones
└── tools/
    └── job-portal-cli/          # herramientas CLI para portales (bun)
```

---

## 3. Flujo de Trabajo

### 3.1 Comando /aplicar

```
Paso 1: Fetch del posting
    │
    ▼
Paso 2: Detector de idioma → { idioma: "es"|"en", region, formalidad }
    │
    ▼
Paso 3: Evaluador de fit (agente) → Score 0-100, fortalezas, gaps
    │
    ├─► Usuario decide continuar
    │
    ▼
Paso 4: Traductor (si idioma=en) → traduce perfil es→en on-the-fly
    │
    ▼
Paso 5: Redactor (task batch en paralelo)
    │       ├─► CV en idioma detectado
    │       └─► Carta en idioma detectado
    │
    ▼
Paso 6: Revisor (agente paralelo) → crítica y verificación
    │
    ▼
Paso 7: Redactor revisa → Output final
    │
    ▼
Paso 8: Compilación + verificación PDF
    │       ├─► lualatex cv/main_<empresa>.tex
    │       ├─► xelatex cover_letters/cover_<empresa>.tex
    │       └─► Verificación: 2 págs CV, 1 pág carta
    │
    ▼
Paso 9: Presentación al usuario (informe en español)
```

### 3.2 Comando /setup

```
Paso 1: Usuario ejecuta /setup
    │
    ▼
Paso 2: Agente ofrece 3 paths:
    │       A. Leer documents/ (si existe)
    │       B. Importar CV único
    │       C. Entrevista estructurada
    │
    ▼
Paso 3: Popula local://perfil.md (en español)
    │
    ▼
Paso 4: Configura preferencias:
    │       - Idioma por defecto: español
    │       - Portales de búsqueda
    │       - Región objetivo
    │       - Tipo de roles
    │
    ▼
Paso 5: Guarda contexto en local://contexto.md
    │
    ▼
Paso 6: (Opcional) Genera traducciones base a inglés
```

### 3.3 Comando /scrape

```
Paso 1: Lee portales configurados
    │
    ▼
Paso 2: Deduplica resultados (hash de URL + título)
    │
    ▼
Paso 3: Presenta lista con fit rating preliminar
    │       - Título, empresa, ubicación
    │       - Score estimado
    │       - Idioma detectado
    │
    ▼
Paso 4: Usuario selecciona postings para /aplicar o /rank
```

---

## 4. Componentes Detallados

### 4.1 Skill: idioma-detector

**Propósito:** Analizar job posting y determinar idioma, región y formalidad.

**Input:**
- Texto completo del job posting o URL

**Proceso:**
1. Extrae texto (browser si es URL, directo si es texto)
2. Analiza:
   - Dominio (.es/.mx/.cl → es, .uk/.com → en, .dk → verificar)
   - Palabras clave ("benefits", "resume" → en; "beneficios", "currículum" → es)
   - Estructura (formato de fecha, headings)
3. Clasifica idioma principal

**Output (JSON):**
```json
{
  "idioma": "es",
  "region": "ES",
  "formalidad": "formal",
  "confianza": 0.95,
  "secundario": null
}
```

**Reglas de detección:**
- 80%+ palabras en un idioma → ese idioma
- Mixto 60-40 → idioma dominante, marcar secundario
- Tech jobs en países no-ingleses → priorizar inglés

---

### 4.2 Skill: traductor

**Propósito:** Traducir perfil desde inglés a cualquier idioma target bajo demanda.

**Input:**
- `local://perfil.md` (en inglés)
- Idioma target: cualquier idioma detectado (`es`, `en`, `da`, `de`, `fr`, `pt`, `it`, `nl`, `sv`, `no`, etc.)

**Estrategia de traducción:**

| Tipo | Estrategia | Ejemplo (en→es) | Ejemplo (en→de) |
|------|-----------|-----------------|-----------------|
| Títulos de sección | Traducción fija | "Experience" → "Experiencia" | "Experience" → "Berufserfahrung" |
| Cargos estándar | Traducción común | "Senior Developer" → "Desarrollador Senior" | "Senior Developer" → "Senior Entwickler" |
| Nombres propios | Sin traducir | "MIT" → mismo | "MIT" → mismo |
| Descripciones de rol | Traducción contextual preservando keywords | "Led team of 5" → "Lideré equipo de 5" | "Led team of 5" → "Habe ein 5-köpfiges Team geleitet" |
| Skills técnicas | Sin traducir | "Python, React, AWS" → mismo | "Python, React, AWS" → mismo |
| Fechas | Formato localizado | "July 8, 2026" → "8 de julio de 2026" | "July 8, 2026" → "8. Juli 2026" |

**Motor de traducción:**
- Usa `web_search` o API externa (DeepL, Google Translate) para traducciones on-the-fly
- Para idiomas con muchos postings (es, de, fr), cachea traducciones frecuentes
- Nombres de empresas/instituciones: investiga si tienen nombre oficial en el idioma target

**Cache:**
- `local://translations-cache.json` almacena traducciones frecuentes
- Key: `{ english_term: { es: "...", de: "...", fr: "..." } }`
- Evita reprocesar mismos términos

**Output:**
- Perfil traducido en memoria (no se guarda archivo permanente)
- Se usa directamente para redacción de CV en idioma target
---

### 4.3 Skill: localizador

**Propósito:** Adaptar formato, tono y convenciones según región.

**Dimensiones de localización:**

| Dimensión | España (ES) | Latinoamérica (LATAM) | Reino Unido (UK) | Estados Unidos (US) |
|-----------|-------------|----------------------|------------------|---------------------|
| Fecha CV | "8 de julio de 2026" | Igual | "8 July 2026" | "July 8, 2026" |
| Saludo carta | "Estimado/a" | Igual | "Dear" | "Dear" |
| Cierre carta | "Atentamente" | Igual | "Yours sincerely" | "Sincerely" |
| Foto CV | No incluir | Depende | No incluir | No incluir |
| Longitud CV | 1-2 págs | 1-2 págs | 1-2 págs | 1 pág |
| Tono | Formal | Formal | Profesional | Directo/impacto |
| Skills section | "Competencias" | Igual | "Skills" | "Skills" |

**Output:**
- Objeto de configuración para plantillas
- Reglas aplicadas durante redacción

---

### 4.4 Plantillas LaTeX

#### CV Español (`plantillas/cv/moderncv-es.tex`)

```latex
\documentclass[11pt,a4paper,sans]{moderncv}
\moderncvstyle{banking}
\moderncvcolor{blue}

% Datos del candidato (se inyectan desde perfil.md)
\name{[NOMBRE]}{[APELLIDOS]}
\title{Currículum Vitae}
\email{email@ejemplo.com}
\phone{+34 600 000 000}
\address{Ciudad, País}

\begin{document}

\section{Perfil Profesional}
[RESUMEN EN ESPAÑOL]

\section{Experiencia Profesional}
\cventry{[FECHA]}{[CARGO EN ESPAÑOL]}{[EMPRESA]}{[UBICACIÓN]}{}{
  \begin{itemize}
    \item [LOGRO EN ESPAÑOL]
  \end{itemize}
}}

\section{Educación}
\cventry{[FECHA]}{[TÍTULO EN ESPAÑOL]}{[INSTITUCIÓN]}{[UBICACIÓN]}{}{}

\section{Competencias}
\cvitem{Idiomas}{Español (nativo), Inglés (avanzado)}
\cvitem{Técnicas}{Python, React, AWS}

\end{document}
```

#### CV Inglés (`plantillas/cv/moderncv-en.tex`)

```latex
\documentclass[11pt,a4paper,sans]{moderncv}
\moderncvstyle{banking}
\moderncvcolor{blue}

% Candidate data (injected from translated profile)
\name{[NAME]}{[SURNAME]}
\title{Curriculum Vitae}
\email{email@example.com}
\phone{+34 600 000 000}
\address{City, Country}

\begin{document}

\section{Professional Profile}
[SUMMARY IN ENGLISH]

\section{Professional Experience}
\cventry{[DATE]}{[TITLE IN ENGLISH]}{[COMPANY]}{[LOCATION]}{}{
  \begin{itemize}
    \item [ACHIEVEMENT IN ENGLISH]
  \end{itemize}
}}

\section{Education}
\cventry{[DATE]}{[DEGREE IN ENGLISH]}{[INSTITUTION]}{[LOCATION]}{}{}

\section{Skills}
\cvitem{Languages}{Spanish (native), English (advanced)}
\cvitem{Technical}{Python, React, AWS}

\end{document}
```

---

### 4.5 Agentes Oh My Pi

#### Agente: Evaluador

**Rol:** Evaluar fit entre perfil del candidato y job posting.

**Contexto:**
- `local://perfil.md` (español)
- Job posting completo (texto)
- Idioma detectado

**Tasks:**
1. Comparar skills requeridas vs perfil
2. Evaluar experiencia (años, nivel, sector)
3. Evaluar fit cultural/behavioral
4. Calcular score 0-100
5. Listar fortalezas (3-5)
6. Listar gaps (3-5)
7. Recomendar proceder o no

**Output:**
```markdown
## Evaluación de Fit: [Empresa] - [Cargo]

### Score: 78/100

### Fortalezas
- ✅ Skill X: 5 años de experiencia directa
- ✅ Sector: mismo industry (fintech)
- ✅ Idioma: nivel C1 requerido, tienes C2

### Gaps
- ⚠️ Skill Y: mencionada como requerida, sin experiencia directa
- ⚠️ Gestión de equipos: posting pide 3+, tienes 1

### Recomendación
Proceder. Los gaps son abordables (Skill Y es "nice-to-have" según contexto).
```

---

#### Agente: Redactor

**Rol:** Escribir CV y carta de presentación en idioma detectado.

**Contexto:**
- Perfil (español) + traducción si needed
- Job posting
- Idioma target
- Plantillas correspondientes

**Tasks:**
1. Seleccionar plantilla (es/en)
2. Adaptar perfil statement al posting
3. Reordenar experiencia por relevancia
4. Resaltar skills que matchean
5. Reconocer gaps honestamente (sin inventar)
6. Escribir carta con tono localizado
7. Aplicar reglas de localización (fecha, saludo, cierre)

**Output:**
- `cv/main_<empresa>_<idioma>.tex`
- `cover_letters/cover_<empresa>_<idioma>.tex`

---

#### Agente: Revisor

**Rol:** Criticar drafts, verificar claims, validar datos.

**Contexto:**
- Drafts de CV y carta
- Perfil original (para verificación factual)
- Job posting
- Información de empresa (web search)

**Tasks:**
1. Verificar factual accuracy (claims vs perfil)
2. Validar keywords del posting cubiertas
3. Revisar tono y localización
4. Sugerir mejoras (3-5 concretas)
5. Marcar errores (gramática, formato, datos empresa)

**Criterios de verificación:**
- [ ] Todos los claims verificables en perfil
- [ ] No se inventaron skills/experiencia
- [ ] Keywords del posting addressing (o gaps honestos)
- [ ] Tono apropiado para región
- [ ] Datos de empresa correctos (web-verificados)

---

## 5. Comandos CLI

### 5.1 `/setup`

**Propósito:** Configurar perfil y preferencias del usuario.

**Sintaxis:**
```bash
python commands/setup.py [--section <skills|experience|search|all>]
```

**Flags:**
- `--section skills`: Re-ejecutar interview de skills
- `--section experience`: Re-ejecutar interview de experiencia
- `--section search`: Reconfigurar queries de búsqueda
- `--section all` (default): Full interview

**Output:**
- `local://perfil.md`
- `local://contexto.md`
- (Opcional) `local://traducciones.json`

---

### 5.2 `/scrape`

**Propósito:** Buscar empleos en portales configurados.

**Sintaxis:**
```bash
python commands/scrape.py [--limit N] [--portal PORTAL1,PORTAL2]
```

**Flags:**
- `--limit N`: Máximo N resultados (default: 50)
- `--portal`: Portales específicos (default: todos configurados)

**Output:**
- Lista de empleos con fit preliminar
- `local://tracker.csv` actualizado

---

### 5.3 `/aplicar`

**Propósito:** Ejecutar flujo completo de aplicación.

**Sintaxis:**
```bash
python commands/aplicar.py <URL|texto>
```

**Input:**
- URL del job posting, o
- Texto completo pastado

**Output:**
- `cv/main_<empresa>_<idioma>.tex`
- `cover_letters/cover_<empresa>_<idioma>.tex`
- PDFs compilados
- `informe.md` (en español con verificación)

---

### 5.4 `/rank`

**Propósito:** Rankear múltiples postings por fit.

**Sintaxis:**
```bash
python commands/rank.py [--ids 1,2,3]
```

**Output:**
- Lista rankeada con scores detallados
- Recomendación de top 3-5

---

### 5.5 `/portales`

**Propósito:** Listar y configurar portales de búsqueda.

**Sintaxis:**
```bash
python commands/portales.py [--add PORTAL] [--remove PORTAL] [--list]
```

---

## 6. Verificación y QA

### 6.1 Checklist por /aplicar

Cada aplicación generada debe pasar:

**Factual accuracy:**
- [ ] Todos los claims verificables en `local://perfil.md`
- [ ] No skills/experiencia inventadas
- [ ] Gaps reconocidos honestamente (no stuffed)
- [ ] Datos de empresa web-verificados

**Targeting:**
- [ ] Profile statement/carta tailored al posting (no genérico)
- [ ] Keywords del posting addressing
- [ ] Skills match highlighted

**Consistencia:**
- [ ] Tono consistente CV + carta
- [ ] No contradicciones entre documentos
- [ ] Formato 2 págs (CV), 1 pág (carta)

**Localización:**
- [ ] Idioma correcto (es/en según posting)
- [ ] Formato de fecha localizado
- [ ] Saludo/cierre apropiado para región
- [ ] Headings en idioma correcto

**Compilación:**
- [ ] CV compila con `lualatex` → exactamente 2 páginas
- [ ] Carta compila con `xelatex` → exactamente 1 página
- [ ] No orphaned entries (títulos solos al final de página)
- [ ] PDFs legibles, fonts correctas

**ATS check (si pdftotext disponible):**
- [ ] Text layer extrae limpio (no garbage)
- [ ] Email/teléfono como texto literal (no iconos)
- [ ] Reading order coincide con visual

---

## 7. Dependencias y Prerequisites

### 7.1 Oh My Pi Tools Requerdos

| Tool | Uso |
|------|-----|
| `agent()` / `task` | Orquestación de agentes |
| `browser` | Fetch de postings, company research |
| `bash` | LaTeX compile, job portal CLIs |
| `read` / `write` | Gestión de archivos |
| `glob` / `grep` | Búsqueda en documentos |

### 7.2 Herramientas Externas

| Herramienta | Uso | Requerido |
|-------------|-----|-----------|
| Bun | Job portal CLIs (TypeScript) | Sí |
| Python 3.10+ | CLI commands | Sí |
| LaTeX (lualatex, xelatex) | Compilación PDFs | Sí |
| pdftotext (poppler) | ATS text extraction | Opcional |
| moderncv package | Plantilla CV | Sí |
| fontspec + fonts | Plantilla carta | Sí |

---

## 8. Migración desde Claude Code

### 8.1 Mapeo Componente por Componente

#### A. Comandos / Entrada de Usuario

| Claude Code | Oh My Pi | Cambios requeridos |
|-------------|----------|-------------------|
| `/apply <URL>` | `python commands/aplicar.py <URL>` | Reescribir lógica en Python; mapear herramientas Claude (`fetch`, `write`) a Oh My Pi (`browser`, `write`, `agent`) |
| `/setup` | `python commands/setup.py` | Reentarvar perfil interview; guardar en `local://perfil.md` (inglés) en vez de `.claude/skills/job-application-assistant/01-candidate-profile.md` |
| `/scrape` | `python commands/scrape.py` | Portar CLI tools de Bun existentes; output en formato Oh My Pi |
| `/rank` | `python commands/rank.py` | Reimplementar scoring con `task` batch parallel |
| `/interview` | `python commands/interview.py` | Pendiente de implementación |
| `/outcome` | `python commands/outcome.py` | Pendiente de implementación |
| `/expand` | `python commands/expand.py` | Pendiente de implementación |
| `/upskill` | `python commands/upskill.py` | Ya existe en `upskill/`; adaptar a Oh My Pi |
| `/add-template` | `python commands/add_template.py` | Pendiente de implementación |
| `/add-portal` | `python commands/add_portal.py` | Pendiente de implementación |
| `/reset` | `python commands/reset.py` | Pendiente de implementación |

#### B. Skills / Conocimiento

| Claude Code (`.claude/skills/job-application-assistant/`) | Oh My Pi (`skills/` o `.omp/agents/`) | Cambios requeridos |
|-------------|----------|-------------------|
| `SKILL.md` | `skills/job-application/SKILL.md` | Traducir a formato Oh My Pi (frontmatter: `name`, `description`, `globs`) |
| `01-candidate-profile.md` | `local://perfil.md` | **Importante:** Traducir contenido a **inglés** para almacenamiento universal |
| `02-behavioral-profile.md` | `local://perfil.md` (sección behavioral) | Mismo formato; traducir a inglés |
| `03-writing-style.md` | `skills/writing-style/SKILL.md` | Adaptar reglas de escritura; añadir soporte multi-idioma |
| `04-job-evaluation.md` | `skills/job-evaluation/SKILL.md` | Reescribir scoring framework; mantener lógica |
| `05-cv-templates.md` | `plantillas/cv/` + `skills/cv-templates/SKILL.md` | Separar plantillas (.tex) de instrucciones (.md) |
| `06-cover-letter-templates.md` | `plantillas/cover/` + `skills/cover-templates/SKILL.md` | Igual que CV |
| `07-interview-prep.md` | `skills/interview-prep/SKILL.md` | Traducir a inglés; mantener framework STAR |

#### C. Agents / Subprocesos

| Claude Code | Oh My Pi | Cambios requeridos |
|-------------|----------|-------------------|
| "Drafter agent" (spawn interno) | `task` con `agent: "redactor"` | Usar `task` tool con `tasks[]` batch; definir agente en `.omp/agents/redactor/AGENT.md` |
| "Reviewer agent" (spawn interno) | `task` con `agent: "revisor"` | Igual; definir en `.omp/agents/revisor/AGENT.md` |
| Agent orchestrator (skill logic) | `commands/aplicar.py` + `task` | Lógica en Python; orquestación con `task` tool |

#### D. Configuración / Settings

| Claude Code | Oh My Pi | Cambios requeridos |
|-------------|----------|-------------------|
| `.claude/settings.json` | `.omp/config.json` o `local://config.md` | Mapear permissions: `Bash(bun run:*)` → bash tool, etc. |
| `.claude/commands/*.md` | `commands/*.py` | Reescribir comandos como scripts Python, no markdown |
| `.claude/skills/` | `skills/` o `.omp/skills/` | Migrar skills a formato Oh My Pi con frontmatter |

#### E. Job Portal Tools

| Claude Code (`.agents/skills/`) | Oh My Pi | Cambios requeridos |
|-------------|----------|-------------------|
| `jobbank-search/cli/` | `tools/job-portal-cli/jobbank.ts` | Mover scripts; mantener lógica Bun |
| `jobdanmark-search/cli/` | `tools/job-portal-cli/jobdanmark.ts` | Igual |
| `jobindex-search/cli/` | `tools/job-portal-cli/jobindex.ts` | Igual |
| `jobnet-search/cli/` | `tools/job-portal-cli/jobnet.ts` | Igual |
| `linkedin-search/cli/` | `tools/job-portal-cli/linkedin.ts` | Igual |

#### F. Output Artifacts

| Claude Code | Oh My Pi | Cambios requeridos |
|-------------|----------|-------------------|
| `cv/main_<company>.tex` | `cv/main_<company>_<idioma>.tex` | Añadir sufijo de idioma; plantilla seleccionada dinámicamente |
| `cover_letters/cover_<company>_<role>.tex` | `cover_letters/cover_<company>_<idioma>.tex` | Igual |
| `documents/applications/<company>_<role>/` | `documents/applications/<company>_<role>/` | Mismo layout; añadir metadata de idioma |
| `job_search_tracker.csv` | `local://tracker.csv` | Mismo formato; posiblemente mover a `local://` |

---

### 8.2 Flujo de Migración Paso a Paso

#### Fase 1: Infraestructura Básica

```bash
# 1. Crear estructura de directorios Oh My Pi
mkdir -p .omp/agents/{evaluador,redactor,revisor,scraper}
mkdir -p .omp/skills/{idioma-detector,traductor,localizador}
mkdir -p commands/
mkdir -p plantillas/{cv,cover}
mkdir -p tools/job-portal-cli/

# 2. Mover job portal CLIs existentes
mv .agents/skills/jobbank-search/cli/* tools/job-portal-cli/
mv .agents/skills/jobdanmark-search/cli/* tools/job-portal-cli/
mv .agents/skills/jobindex-search/cli/* tools/job-portal-cli/
mv .agents/skills/jobnet-search/cli/* tools/job-portal-cli/
mv .agents/skills/linkedin-search/cli/* tools/job-portal-cli/
```

#### Fase 2: Migración de Skills

```bash
# 3. Traducir perfil a inglés y guardar en local://
# (esto se hace durante el /setup inicial, no manualmente)

# 4. Crear skills Oh My Pi
# Cada skill necesita:
# - SKILL.md con frontmatter (name, description, globs)
# - Archivos de conocimiento referenced via skill://...
```

**Ejemplo: `skills/idioma-detector/SKILL.md`**

```markdown
---
name: idioma-detector
description: Detecta idioma, región y formalidad de un job posting
globs: []
alwaysApply: false
---

# Skill: Detector de Idioma

Analiza job postings y determina...
```

#### Fase 3: Crear Agentes

**Ejemplo: `.omp/agents/evaluador/AGENT.md`**

```markdown
---
name: evaluador
description: Evalúa fit entre perfil y job posting
spawns: false
---

# Agente: Evaluador de Fit

## Rol
Evaluar compatibilidad entre el perfil del candidato y un job posting.

## Contexto
- `local://perfil.md` (inglés)
- Job posting completo
- Idioma detectado

## Tasks
1. Comparar skills requeridas vs perfil
...
```

#### Fase 4: Implementar Commands CLI

**Ejemplo: `commands/aplicar.py`**

```python
#!/usr/bin/env python3
"""
/aplicar - Ejecuta flujo completo de aplicación
Usage: python commands/aplicar.py <URL|texto>
"""

import sys
from pathlib import Path

def main():
    if len(sys.argv) < 2:
        print("Error: Proporcione URL o texto del job posting")
        sys.exit(1)
    
    job_input = sys.argv[1]
    
    # Paso 1: Fetch del posting
    posting_text = fetch_job(job_input)
    
    # Paso 2: Detectar idioma
    idioma_info = detect_language(posting_text)
    
    # Paso 3: Evaluar fit (agente)
    fit_result = evaluate_fit(posting_text)
    
    # ... continuar flujo
```

#### Fase 5: Plantillas Multi-idioma

```bash
# 5. Crear plantillas base (español + inglés como mínimos)
# Luego añadir headers localizados para otros idiomas
```

**Estructura de plantilla:**

```latex
% plantillas/cv/moderncv-base.tex
% Headers localizados se inyectan según idioma

\section{SECTION_EXPERIENCE}  % Placeholder → "Experience" / "Experiencia" / "Berufserfahrung"
```

#### Fase 6: Testing

```bash
# 6. Testear con postings reales en múltiples idiomas
python commands/aplicar.py https://jobindex.dk/job/...   # Danés/Inglés
python commands/aplicar.py https://infojobs.net/...       # Español
python commands/aplicar.py https://seek.com.au/...        # Inglés AU
```

---

### 8.3 Qué se conserva

| Componente | Estado | Notas |
|------------|--------|-------|
| Plantillas LaTeX base | ✅ Reutilizar | Traducir headings; añadir soporte multi-idioma |
| Perfil del candidato | ✅ Migrar | **Traducir a inglés** para `local://perfil.md` |
| Job portal CLIs | ✅ Mover | De `.agents/skills/` a `tools/job-portal-cli/`; mantener lógica Bun |
| Estructura documents/ | ✅ Mismo layout | `documents/applications/`, `documents/cv/`, etc. |
| Flujo drafter-reviewer | ✅ Reimplementar | Con `task` batch en Oh My Pi |
| LaTeX compile flow | ✅ Mismo proceso | `lualatex` para CV, `xelatex` para carta |
| ATS verification | ✅ Mantener | `pdftotext` + verificación de text layer |

---

### 8.4 Qué se reescribe

| Componente | Estado | Razón |
|------------|--------|-------|
| Comandos (`/apply`, `/setup`) | ❌ Reescribir en Python CLI | Claude Code commands (.md) no compatibles con Oh My Pi |
| Skills markdown (`.claude/skills/`) | ❌ Reescribir formato | Oh My Pi requiere frontmatter específico (`name`, `description`, `globs`) |
| Settings (`.claude/settings.json`) | ❌ Adaptar | Oh My Pi usa otro sistema de config |
| Orquestación de agentes | ❌ Reimplementar | Claude Code spawn interno → Oh My Pi `task` tool |
| Perfil (almacenamiento) | ❌ Traducir a inglés | Requisito para multi-idioma output |
| Interfaz de usuario | ❌ Adaptar | Claude Code terminal UI → Oh My Pi chat/conversación |

---

### 8.5 Breaking Changes

| Cambio | Impacto | Mitigación |
|--------|---------|------------|
| Perfil en inglés (no español) | Usuario debe tener perfil traducido | `/setup` hace traducción inicial asistida |
| Commands ahora son scripts Python | No más `/apply` en Claude Code | Documentar nuevos comandos; crear aliases |
| Skills formato Oh My Pi | Skills existentes no loadean | Reescribir con frontmatter; mantener semántica |
| Agentes vía `task` tool | Sintaxis de spawn diferente | Actualizar patrones de orquestación |

---

## 9. Próximos Pasos

### Fase 1: Infraestructura (Semana 1)

- [ ] Crear estructura de directorios Oh My Pi (`.omp/`, `skills/`, `commands/`, `plantillas/`)
- [ ] Mover job portal CLIs de `.agents/skills/` a `tools/job-portal-cli/`
- [ ] Configurar `local://` root para perfil y contexto
- [ ] Crear `commands/setup.py` (primer comando para poblar perfil)

### Fase 2: Skills Core (Semana 2)

- [ ] `skills/idioma-detector/SKILL.md` - detección multi-idioma
- [ ] `skills/traductor/SKILL.md` - traducción inglés → cualquier idioma
- [ ] `skills/localizador/SKILL.md` - reglas regionales
- [ ] `skills/job-evaluation/SKILL.md` - scoring framework
- [ ] Traducir perfil existente a inglés (durante `/setup`)

### Fase 3: Agentes (Semana 2-3)

- [ ] `.omp/agents/evaluador/AGENT.md`
- [ ] `.omp/agents/redactor/AGENT.md`
- [ ] `.omp/agents/revisor/AGENT.md`
- [ ] `.omp/agents/scraper/AGENT.md`
- [ ] Testear spawning con `task` tool

### Fase 4: Commands CLI (Semana 3)

- [ ] `commands/aplicar.py` - flujo completo
- [ ] `commands/scrape.py` - integración portales
- [ ] `commands/rank.py` - scoring batch
- [ ] `commands/setup.py` - configuración inicial
- [ ] Documentar uso (README en español)

### Fase 5: Plantillas (Semana 4)

- [ ] `plantillas/cv/moderncv-base.tex` - estructura común
- [ ] `plantillas/cv/headers-es.tex` - español
- [ ] `plantillas/cv/headers-en.tex` - inglés
- [ ] `plantillas/cv/headers-de.tex` - alemán
- [ ] `plantillas/cv/headers-fr.tex` - francés
- [ ] `plantillas/cover/cover-base.cls`
- [ ] `plantillas/cover/headers-*.tex` (mismo patrón)
- [ ] Test compile para cada idioma

### Fase 6: Testing & QA (Semana 4-5)

- [ ] Test `/aplicar` con postings en:
  - [ ] Español (InfoJobs, LinkedIn España)
  - [ ] Inglés (LinkedIn UK/US, Indeed)
  - [ ] Danés (Jobindex DK)
  - [ ] Alemán (StepStone DE)
- [ ] Verificar compilación PDF todos los idiomas
- [ ] Verificar ATS check (si pdftotext disponible)
- [ ] Test `/setup` flow completo

### Fase 7: Documentación (Semana 5)

- [ ] Actualizar README.md (en español)
- [ ] Actualizar SETUP.md (en español)
- [ ] Migrar documentación de skills
- [ ] Ejemplos de uso

---

## 10. Appendix

### A. Glosario de Términos


| Español | Inglés |
|---------|--------|
| Candidato | Candidate |
| Currículum | CV / Resume |
| Carta de presentación | Cover letter |
| Puesto / Cargo | Role / Position |
| Habilidades / Competencias | Skills |
| Experiencia profesional | Professional experience |
| Logro | Achievement |
| Brecha / Gap | Gap |
| Ajuste / Fit | Fit |

### B. Referencias

- Oh My Pi docs: `omp://`
- Skill authoring: `omp://skills.md`
- Task agent: `omp://tools/task.md`
- Proyecto original: `README.md`, `CLAUDE.md`

---

**Fin del documento de diseño**