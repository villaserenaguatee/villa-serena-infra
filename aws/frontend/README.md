# Frontend Next.js en AWS Amplify Hosting

Infraestructura del frontend Next.js 15 SSR/ISR en Amplify, con state en R2.

## GitHub Actions

Configura los siguientes secretos en `villa-serena-infra`:

- `R2_ACCESS_KEY_ID` y `R2_SECRET_ACCESS_KEY` (backend Terraform).
- `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` (proveedor AWS; permisos de Amplify).
- `AMPLIFY_GITHUB_ACCESS_TOKEN` (token para conectar el repositorio web; nunca lo guardes en tfvars).

Variable opcional: `AWS_REGION` (por defecto `us-east-1`).

El workflow valida los cambios en PR. Ejecuta manualmente `Terraform Frontend Plan` para obtener el plan sin crear recursos.

**No hay apply automático.** Tras revisar el plan, el despliegue debe habilitarse por separado.

## DNS

El dominio previsto es `web.villaserenaguate.lat`. Tras crear la asociación en Amplify, configura en Cloudflare los registros de validación y del subdominio indicados por AWS. No se modifica el módulo `cloudflare/dns` hasta conocer los valores generados.

## Precaución

El token de GitHub se entrega como variable efímera para evitar almacenarlo como entrada de Terraform; confirma el comportamiento de la versión del provider antes de aplicar. Amplify puede requerir permisos adicionales del token para conectar el repositorio.
