# AGENTS.md — Reglas para la IA en los repositorios de Villa Serena

> Copia este archivo en la raíz de **cada uno de los 5 repositorios**. Las herramientas de IA (Claude Code, Codex, Copilot, Cursor) lo leen como instrucciones del proyecto. Si tu herramienta usa otro nombre (por ejemplo, `CLAUDE.md`), crea una copia con ese nombre.

---

## 1. Qué es el proyecto

PMS (sistema de administración hotelera) para el hotel boutique **ficticio** "Villa Serena". Proyecto final del curso de Desarrollo Web.

- **Hito:** sábado 10 de octubre de 2026. El flujo principal debe funcionar **en local con Docker**: reservar → check-in → estadía (app) → operación → check-out con factura.
- **No hay producción todavía:** sin VPS, Cloudflare, CI/CD ni backups hasta después del hito.
- **El hotel es ficticio:** sin dinero real (Stripe en modo prueba), sin facturación ante la SAT, sin huéspedes reales.

## 2. Reglas de trabajo para la IA

1. **Idioma:** responde, explica y comenta en **español**. El código, los nombres de clases, variables y endpoints técnicos van en inglés o en español según la convención del documento 14 (rutas `/api/v1/...`, paquete `gt.villaserena`).
2. **No inventes alcance.** Implementa **solo** lo que pide el prompt del objetivo y los documentos adjuntos. No agregues pantallas, estados, validaciones, campos ni dependencias "por si acaso". Si algo parece faltar, **pregunta** antes de agregarlo.
3. **Primero el plan, después el código.** Antes de escribir, muestra un plan corto (archivos a crear o cambiar). Trabaja en pasos pequeños y verificables.
4. **Los documentos mandan.** Si el prompt y un documento se contradicen, gana el documento y avisa de la contradicción.
5. **Versiones fijas** (no las cambies sin que el equipo lo apruebe):

| Pieza | Versión |
|---|---|
| Backend | Spring Boot **4.1**, Java **21**, Maven |
| Base de datos | PostgreSQL **17**, Flyway |
| Web | Next.js **15** (App Router), React 19, TypeScript, Tailwind 4, shadcn/ui |
| App | React Native con Expo **SDK 54**, Expo Router |
| Gestor de paquetes JS | pnpm |

   Spring Boot 4 usa los starters `spring-boot-starter-webmvc`, `spring-boot-starter-security-oauth2-resource-server` y `spring-boot-starter-flyway`.

6. **Zona horaria:** las fechas se guardan en UTC y se muestran o calculan en **America/Guatemala** (AD-19).
7. **Pruebas mínimas:** cada cambio debe poder demostrarse con los pasos de "Cómo saber que quedó terminado" de su prompt.

## 3. Seguridad (obligatorio)

- **Nunca subir secretos a Git. Los secretos van solo en un `.env` fuera de Git o en GitHub Secrets. Nunca pegar claves secretas en un chat de IA.**
- En el repositorio solo va `.env.example`, con los nombres de las variables y valores de ejemplo, nunca reales.
- `.env` debe estar en `.gitignore` desde el primer commit.
- Si necesitas una clave para probar, usa un marcador (`<TU_CLAVE>`) y pide al integrante que la ponga en su `.env`.

## 4. Git

- **Nunca trabajes directo en `main`.** Una rama por tarea, por ejemplo `obj0-seguridad-jwt`.
- Pull requests pequeños, con una descripción corta de qué se hizo y cómo se probó.
- Mensajes de commit en español, cortos: `obj0: agrega login del personal`.

## 5. Piezas compartidas (no tocar sin coordinar)

| Pieza | Regla |
|---|---|
| Migraciones de Flyway | **Solo Josué** las crea. Si necesitas una tabla o columna, pídela; no crees archivos `V*__*.sql` |
| `openapi.yaml` (contrato del API) | Los cambios pasan por **Josué** y se avisan al grupo. La web y la app copian el archivo y generan sus tipos |
| Spring Security | Lo arma **Pablo**; los demás solo agregan reglas de sus rutas |
| Cliente de tiempo real de la web | Lo arma **Alex**; los demás lo reutilizan |

## 6. Sección por repositorio

### villa-serena-infra
- Contiene `docker-compose.dev.yml` (PostgreSQL 17, Mailpit, MinIO, Prometheus y Grafana), la configuración de Prometheus, el tablero de Grafana y `.env.example`.
- Comando: `docker compose -f docker-compose.dev.yml up -d`.
- No agregues el API, la web ni la app a Docker en el hito: corren en la computadora de cada integrante.

### villa-serena-api
- Spring Boot 4.1, paquete raíz `gt.villaserena`, módulos según el documento 14 (sección 7).
- Endpoints bajo `/api/v1/...`. Cada rol recibe un **DTO** con solo lo que puede ver; nunca se devuelve la entidad.
- Las reglas viven en Spring y en la base de datos, no solo en la interfaz (documento 14, sección 5).
- Comando: `./mvnw spring-boot:run` (Flyway crea las tablas y carga los datos iniciales).

### villa-serena-web
- Next.js 15 como **BFF**: el navegador solo habla con Next.js; los tokens van en cookies httpOnly y nunca llegan al navegador (documento 14, sección 6.1).
- Tipos del API generados con `openapi-typescript` desde la copia local de `openapi.yaml`.
- Comando: `pnpm dev` (http://localhost:3000).

### villa-serena-movil
- Expo SDK 54 + Expo Router. La app llama **directo** a Spring con su propio JWT guardado en `expo-secure-store` (no usa el BFF).
- Pruebas rápidas con **Expo Go de SDK 54** (se instala desde expo.dev/go, no desde la Play Store). Push solo con el development build.
- Comando: `npx expo start`.

### villa-serena-docs
- Documentación V3. No se genera código aquí.
