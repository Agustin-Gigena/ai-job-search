# AI Job Search para Oh My Pi - Diseño de Arquitectura

**Fecha:** 2026-07-08  
**Autor:** AI Job Search Migration Project  
**Estado:** Aprobado para implementación  
**Idioma del sistema:** Español  
**Idiomas de output:** Español (interfaz), Español/Inglés (CV y carta según job posting)

---

## 1. Resumen Ejecutivo

Migración completa del framework AI Job Search desde Claude Code a Oh My Pi, con detección automática de idioma (español/inglés) y traducción automática del CV cuando sea necesario.

### Decisiones Clave

| Área | Decisión |
|------|----------|
| Perfil base | Solo en español |
| Idioma de comunicación | Español (todo el output, comandos, mensajes) |
| Traducción de CV | Automática (es→en on-the-fly cuando el posting es en inglés) |
| Enfoque de migración | Port nativo completo a Oh My Pi |
| Plantillas | Dual-language (es + en) |

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

**Propósito:** Traducir perfil de español a inglés bajo demanda.

**Input:**
- `local://perfil.md`
- Idioma target: `en`

**Estrategia de traducción:**

| Tipo | Estrategia | Ejemplo |
|------|-----------|---------|
| Títulos de sección | Traducción fija | "Experiencia" → "Professional Experience" |
| Cargos estándar | Traducción común | "Desarrollador Senior" → "Senior Developer" |
| Nombres propios | Sin traducir | "Universidad Complutense" → mismo |
| Descripciones de rol | Traducción contextual preservando keywords | "Lideré equipo de 5" → "Led team of 5" |
| Skills técnicas | Sin traducir | "Python, React, AWS" → mismo |

**Cache:**
- `local://traducciones.json` almacena traducciones frecuentes
- Key: término en español → Value: traducción en inglés
- Evita reprocesar mismos términos

**Output:**
- Perfil traducido en memoria (no se guarda archivo)
- Se usa directamente para redacción de CV en inglés

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

### 8.1 Qué se conserva

| Componente | Estado |
|------------|--------|
| Plantillas LaTeX base | ✅ Reutilizar (traducir headings) |
| Perfil del candidato | ✅ Migrar contenido a `local://perfil.md` |
| Job portal CLIs | ✅ Mover de `.agents/skills/` a herramientas reusables |
| Estructura documents/ | ✅ Mismo layout |
| Flujo drafter-reviewer | ✅ Reimplementar con `task` batch |

### 8.2 Qué se reescribe

| Componente | Estado |
|------------|--------|
| Comandos (`/apply`, `/setup`) | ❌ Reescribir en Python CLI |
| Skills markdown (`.claude/skills/`) | ❌ Reescribir como Oh My Pi skills/agents |
| Settings (`.claude/settings.json`) | ❌ Adaptar a config de Oh My Pi |
| Orquestación de agentes | ❌ Reimplementar con `task` tool |

---

## 9. Próximos Pasos

1. **Crear estructura de agentes** (`.omp/agents/`)
2. **Escribir skills** (`.omp/skills/` o `skills/`)
3. **Implementar CLI commands** (Python)
4. **Traducir plantillas** (es + en)
5. **Migrar perfil existente** → `local://perfil.md`
6. **Testear flujo completo** con posting real
7. **Documentar usage** en README (en español)

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