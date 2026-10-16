# villa-serena-infra

Entorno local del hito (10 de octubre de 2026) con Docker Compose: PostgreSQL 17, Mailpit, MinIO, Prometheus y Grafana.
El API, la web y la app **no** corren en Docker: se ejecutan en la computadora de cada integrante (documento 14, sección 8).

## Requisitos

- Docker Desktop (o Docker Engine + Compose) encendido.

## Cómo arrancar

1. Crea tu `.env` a partir del ejemplo y cambia las contraseñas `<TU_...>` (MinIO pide al menos 8 caracteres):

   ```bash
   cp .env.example .env
   ```

2. Levanta los servicios:

   ```bash
   docker compose -f docker-compose.dev.yml up -d
   ```

3. Revisa el estado:

   ```bash
   docker compose -f docker-compose.dev.yml ps -a
   ```

   Deben aparecer `postgres`, `mailpit`, `minio`, `prometheus` y `grafana` en estado *running*.
   `minio-init` aparece como *exited (0)*: es normal, solo crea los buckets y termina.

## URLs de cada servicio

| Servicio | URL / dirección | Credenciales |
|---|---|---|
| PostgreSQL | `localhost:5432` | `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` del `.env` |
| Mailpit (SMTP) | `localhost:1025` | Sin autenticación |
| Mailpit (web) | http://localhost:8025 | — |
| MinIO (API S3) | http://localhost:9000 | `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD` |
| MinIO (consola) | http://localhost:9001 | `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD` |
| Prometheus | http://localhost:9090 (objetivos: `/targets`) | — |
| Grafana | http://localhost:3001 | `GRAFANA_ADMIN_USER`, `GRAFANA_ADMIN_PASSWORD` |

### Buckets de MinIO

| Variable | Acceso | Contenido |
|---|---|---|
| `MINIO_BUCKET_PUBLIC` | Lectura pública | Fotos del hotel, tipos de habitación, menú y amenidades |
| `MINIO_BUCKET_PRIVATE` | Privado (URL firmadas desde el API) | PDF de facturas y fotos de incidencias |

> **Nota:** Las imágenes oficiales de MinIO ya no están en Docker Hub; se usa el fork
> [`pgsty/minio`](https://hub.docker.com/r/pgsty/minio) (y `pgsty/mc`), compatible con S3.

### Monitoreo

- Prometheus lee `http://host.docker.internal:8080/actuator/prometheus` cada 15 s (el API corre fuera de Docker).
- Grafana trae aprovisionados el datasource de Prometheus y el tablero **Villa Serena — API** (carpeta *Villa Serena*):
  estado del API, peticiones por segundo, errores 4xx y 5xx, CPU y memoria de la JVM.
- Mientras el API no esté corriendo, el objetivo aparece **DOWN** en Prometheus y el tablero sin datos. Es lo esperado.

## Cómo apagar

Detener los servicios conservando los datos:

```bash
docker compose -f docker-compose.dev.yml down
```

Detener y **borrar todos los datos** (base de datos, correos, archivos, métricas y Grafana):

```bash
docker compose -f docker-compose.dev.yml down -v
```
