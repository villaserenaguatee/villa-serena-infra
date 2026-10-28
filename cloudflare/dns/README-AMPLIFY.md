## Migración DNS a Amplify

1. Aplicar `aws/frontend` y esperar a que Amplify muestre los registros del dominio.
2. Copiar el **destino CNAME exacto** del subdominio `web` a `TF_VAR_amplify_cname_target`.
3. Configurar `TF_VAR_zone_id` y `CLOUDFLARE_API_TOKEN`.
4. Si `web` ya existe en Cloudflare, **importarlo** al estado de `cloudflare/dns` antes del apply. No crear un registro duplicado.
5. Ejecutar `terraform plan` y luego `terraform apply` en `cloudflare/dns`. Añadir también el CNAME de validación de certificado que Amplify indique, si corresponde.
6. Verificar el estado del dominio en Amplify y la respuesta HTTPS antes de retirar el despliegue anterior.

El estado de `cloudflare/dns` todavía no existe. No ejecutar apply a ciegas si el registro DNS ya existe.
