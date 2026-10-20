# villa-serena-infra

Infraestructura de Villa Serena: Terraform para AWS/Cloudflare, Ansible para EC2/PostgreSQL y servicios auxiliares locales. **MinIO se retira**: el API usa R2 remoto en `dev` y Amazon S3 en `prod`. Mailpit permanece.

## Empezar

- [Entornos del API: local, dev y prod](https://github.com/villaserenaguatee/villa-serena-api/blob/dev/docs/ENTORNOS.md): arranque recomendado con Docker o Maven.
- [Almacenamiento: R2 y S3](docs/ALMACENAMIENTO.md): aprovisionamiento, permisos, configuración y comprobación, paso a paso.
- [EC2 con Ansible](ansible/README.md) y [PostgreSQL](ansible/POSTGRESQL.md).

## Servicios locales sin el API

El Compose histórico de infra conserva PostgreSQL, Mailpit, Prometheus y Grafana para ejecutar el API en el host. No lo ejecutes junto al stack de API sobre los mismos puertos.

1. Copia `.env.example` a `.env` y completa las contraseñas privadas.
2. Valida y arranca:

```bash
docker compose -f docker-compose.dev.yml config --quiet
docker compose -f docker-compose.dev.yml up -d
```

| Servicio | Dirección |
|---|---|
| PostgreSQL | `localhost:5432` |
| Mailpit | `http://localhost:8025`; SMTP `localhost:1025` |
| Prometheus | `http://localhost:9090` |
| Grafana | `http://localhost:3001` |

Configura R2 en `.env.dev` del API; no hay servidor de objetos local. Prometheus conserva como destino `host.docker.internal:8080` y Grafana mantiene su tablero provisionado. Sin API, el destino aparecerá DOWN.

Para detener conservando datos:

```bash
docker compose -f docker-compose.dev.yml down
```

No se eliminan volúmenes ni archivos anteriores como parte de esta reorganización; revisa la sección de transición de la guía de almacenamiento.
