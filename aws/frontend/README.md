# Frontend Next.js en AWS Amplify Hosting

Infraestructura del frontend Next.js 15 SSR/ISR en Amplify, con state en R2.

## GitHub Actions

Configura los siguientes secretos en `villa-serena-infra`:

- `R2_ACCESS_KEY_ID` y `R2_SECRET_ACCESS_KEY` (backend Terraform).
- `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` (proveedor AWS; permisos de Amplify).
- `AMPLIFY_GITHUB_ACCESS_TOKEN` (token para conectar el repositorio web; nunca lo guardes en tfvars).

Variable opcional: `AWS_REGION` (por defecto `us-east-1`).

El workflow ejecuta `terraform fmt`, `terraform validate` y, si pasan, `terraform plan` automáticamente en cada PR y en los cambios relevantes de `main`. También permite ejecución manual.

**No hay apply automático.** El despliegue y el corte DNS deben realizarse por separado para no interrumpir la web anterior.

## DNS

El dominio previsto es `web.villaserenaguate.lat`. Tras crear la asociación en Amplify, configura en Cloudflare los registros de validación y del subdominio indicados por AWS. El módulo `cloudflare/dns` recibe el destino CNAME mediante `TF_VAR_amplify_cname_target`. Consulta `cloudflare/dns/README-AMPLIFY.md` antes de aplicar. Si el registro DNS ya existe, impórtalo al estado antes del apply.

## Precaución

El token de GitHub se pasa mediante GitHub Secrets. Trátalo como credencial sensible y restringe el acceso al state remoto: el provider podría conservar datos sensibles en el state. Amplify puede requerir permisos adicionales del token para conectar el repositorio.
