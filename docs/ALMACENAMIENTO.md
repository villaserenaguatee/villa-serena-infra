# Almacenamiento: R2 en desarrollo y S3 en producción

Decisión: retirar MinIO. `local` mínimo del API conserva su adaptador privado en PostgreSQL; `dev` prueba R2 real desde la computadora y `prod` utiliza S3. Mailpit permanece para correo local. Los tres perfiles y sus comandos están en [ENTORNOS del API](https://github.com/villaserenaguatee/villa-serena-api/blob/dev/docs/ENTORNOS.md).

Escribir o validar Terraform **no demuestra que se hayan creado recursos**. `init -backend=false` y `validate` no aprovisionan. Revisa siempre `plan` antes de `apply`. AWS ya se aplicó y comprobó según el registro siguiente; `cloudflare/storage` no se ejecutó en ese aprovisionamiento.

## Aprovisionamiento AWS verificado — 2026-10-20 UTC

Se aplicó el plan de `aws/storage` con el proveedor AWS y backend R2 existentes:
**20 recursos creados, 0 modificados y 0 eliminados**. El plan posterior confirmó
`No changes`. No se recrearon EC2, su rol ni la red.

| Salida | Valor |
|---|---|
| Región | `us-east-1` |
| Bucket de fotos públicas vía CDN | `villa-serena-prod-public-291723764646-us-east-1` |
| Bucket privado del API | `villa-serena-prod-private-291723764646-us-east-1` |
| CloudFront (`Deployed`, habilitado) | `E1ZDTM6THJAMS0` |
| URL pública de assets | `https://d13s29erv78l4g.cloudfront.net` |
| Rol EC2 existente | `villa-serena-prod-ec2-role` |

Se publicaron las 17 fotos aprobadas de `web/public/images/catalogo-aprobado/`
bajo `images/catalogo-aprobado/`, sin borrar archivos ni objetos anteriores.
Para las 17 se comprobó HTTP `200` por CloudFront, SHA-256 idéntico al original y
HTTP `403` anónimo directo en S3. También se verificaron redirección HTTP → HTTPS,
CORS para `https://web.villaserenaguate.lat`, tipo JPEG, caché inmutable, cifrado
AES256, versionado y los cuatro bloqueos de acceso público del bucket.

Foto de ejemplo lista para consumir:

```text
https://d13s29erv78l4g.cloudfront.net/images/catalogo-aprobado/a27a019011086cef.jpg
```

Para producción, la salida de URL corresponde a
`ARCHIVOS_URL_PUBLICA=https://d13s29erv78l4g.cloudfront.net`. Para mostrar estas
fotos, la web solo necesita su URL pública, sin credenciales AWS ni configurar el
nombre del bucket. En este paso no se modificaron
parámetros SSM, datos del API, código web ni sus despliegues; la actualización de
referencias se describe en «Fotos de habitaciones».

## Qué administra cada directorio

| Directorio | Recursos | Estado remoto independiente |
|---|---|---|
| `cloudflare/storage` | R2 `villa-serena-dev-public`, `villa-serena-dev-private`, dominio público y CORS | `cloudflare/storage/terraform.tfstate` |
| `aws/storage` | Dos buckets S3 privados, cifrado, versionado, CloudFront/OAC para assets públicos y política acotada al rol EC2 existente | `aws/storage/terraform.tfstate` |

Ambos usan el backend R2 ya existente, con el perfil `r2-terraform`. Los proveedores y sus versiones se reutilizan de la configuración existente; sus locks se conservan. Cada directorio necesita su inicialización local. El bucket `villa-serena-terraform-state` no guarda archivos de la aplicación y no se modifica su definición.

Los buckets tienen `prevent_destroy`; S3 usa también `force_destroy=false`, acceso público bloqueado, propietario de bucket obligatorio y HTTPS. No se crean usuarios IAM ni claves AWS permanentes. CloudFront solo puede leer el bucket de assets públicos de esa distribución; no puede leer facturas ni incidencias. El rol EC2 puede leer/escribir el bucket privado, consultar su existencia y borrar únicamente objetos de comprobación bajo `_checks/`.

## 1. Preparar R2 para pruebas locales

- [ ] Requisitos: Terraform >= 1.10, cuenta Cloudflare con R2 habilitado y dominio en la misma cuenta. Usa el backend/perfil `r2-terraform` existente; no copies esas credenciales a la aplicación.
- [ ] Inyecta `CLOUDFLARE_API_TOKEN` en tu terminal por un mecanismo privado. Es el token administrativo de Terraform, con permiso `Workers R2 Storage Write` en esa cuenta; no es la clave S3 del API.
- [ ] Desde `villa-serena-infra`, copia la plantilla de identificadores no secretos y completa `cloudflare_account_id` y `cloudflare_zone_id`:

```bash
cp cloudflare/storage/terraform.tfvars.example cloudflare/storage/terraform.tfvars
terraform -chdir=cloudflare/storage init
terraform -chdir=cloudflare/storage fmt -check
terraform -chdir=cloudflare/storage validate
terraform -chdir=cloudflare/storage plan -out=storage.tfplan
```

- [ ] Revisa que el plan solo cree recursos de almacenamiento de desarrollo y su dominio; no debe reemplazar buckets existentes ni tocar compute, red o el estado de otros directorios. Si ya existe un bucket con esos nombres, revisa/importa su gestión antes de aplicar.
- [ ] Aplica el plan revisado y consulta salidas:

```bash
terraform -chdir=cloudflare/storage apply storage.tfplan
terraform -chdir=cloudflare/storage output
```

- [ ] En Cloudflare, confirma que el dominio de assets públicos está activo y su certificado emitido. Los dominios `r2.dev` se mantienen deshabilitados y el bucket privado no tiene dominio público.
- [ ] En **R2 → Manage R2 API Tokens**, crea una credencial de aplicación con **Object Read & Write**, limitada a `villa-serena-dev-private`. Guarda su Access Key ID y Secret Access Key en tu archivo privado `.env.dev` del API. Crea la credencial de subida de assets públicos aparte si la necesitas. No uses el token administrativo ni el perfil del estado Terraform para ejecutar el API.
- [ ] Completa en `.env.dev` del API:

```dotenv
STORAGE_ENDPOINT=https://ACCOUNT_ID.r2.cloudflarestorage.com
STORAGE_REGION=auto
STORAGE_ACCESS_KEY_ID=REPLACE_PRIVATELY
STORAGE_SECRET_ACCESS_KEY=REPLACE_PRIVATELY
STORAGE_BUCKET_PRIVATE=villa-serena-dev-private
STORAGE_PATH_STYLE=true
ARCHIVOS_URL_PUBLICA=https://assets-dev.villaserenaguate.lat
```

`storage_endpoint` y `public_assets_url` de Terraform dan los valores reales. Para firmar descargas privadas se utiliza el endpoint S3 de R2, nunca el dominio público de assets.

- [ ] Levanta el API en `dev` siguiendo su guía. Desde API, comprueba R2 con el SDK real:

```bash
STORAGE_SMOKE_TEST=true ./mvnw -B -Dtest=AlmacenS3RemoteTest test
```

En PowerShell define `$env:STORAGE_SMOKE_TEST='true'` antes de Maven y elimina la variable al terminar. La prueba no arranca el API ni toca SQL. Escribe un objeto único bajo `_checks/`, comprueba HEAD/GET/URL firmada y rechazo de GET anónimo, y lo elimina. Su omisión normal en CI no acredita conectividad remota.

## 2. Preparar S3 de producción

- [ ] Requisitos: rol EC2 ya creado por `aws/compute`, permisos de operador para administrar S3/CloudFront y añadir una política al rol. Conserva las credenciales del proveedor AWS separadas del perfil R2 del backend.
- [ ] Confirma región y `allowed_origins` en `aws/storage/variables.tf`. Por defecto son `us-east-1` y `https://web.villaserenaguate.lat`; puedes pasar valores no secretos mediante `terraform.tfvars` ignorado por Git.
- [ ] Inicializa, valida y prepara el plan desde infra:

```bash
terraform -chdir=aws/storage init
terraform -chdir=aws/storage fmt -check
terraform -chdir=aws/storage validate
terraform -chdir=aws/storage plan -out=storage.tfplan
```

- [ ] Revisa que el plan solo cree los dos buckets, su configuración, distribución/OAC y una política al rol existente. No recrea EC2, su rol ni la red. Los nombres incluyen cuenta y región para evitar colisiones globales.
- [ ] Aplica el plan revisado:

```bash
terraform -chdir=aws/storage apply storage.tfplan
terraform -chdir=aws/storage output
```

- [ ] Espera a que CloudFront termine de desplegarse. `public_assets_url` será una URL HTTPS de CloudFront; no hace falta configurar un nuevo dominio DNS para usarla.
- [ ] En Parameter Store, bajo `/villa-serena/prod/api/`, configura valores de tipo String con las salidas:

| Parámetro | Valor |
|---|---|
| `STORAGE_BUCKET_PRIVATE` | `private_bucket` |
| `STORAGE_REGION` | `storage_region` |
| `STORAGE_PATH_STYLE` | `false` |
| `ARCHIVOS_URL_PUBLICA` | `public_assets_url` |
| `APP_DOWNLOAD_URL` | URL pública del APK, si existe |

- [ ] Omite o deja vacío `STORAGE_ENDPOINT`. Retira las antiguas variables `MINIO_*` y las claves estáticas `STORAGE_ACCESS_KEY_ID`, `STORAGE_SECRET_ACCESS_KEY` si existen. El SDK usa credenciales temporales del rol EC2; el host actual ya requiere IMDSv2 y tiene hop limit 2 para contenedores. Conserva `JWT_SECRET`, configuración de datos, `WEB_URL` y `CORS_ORIGENES` del despliegue.
- [ ] Vuelve a desplegar el API mediante su CD y comprueba `/actuator/health`. La salud no valida S3: comprueba además una operación real de archivo autorizada desde la aplicación al disponer de sus datos operativos.

### Comprobación explícita de S3 antes de habilitar la función

La misma prueba remota admite S3. Ejecútala desde un checkout de API con Java 21 y credenciales temporales del operador o un perfil AWS compatible del SDK (distintas del perfil `r2-terraform`). **No cargues `.env.dev` de R2**:

```bash
STORAGE_SMOKE_CONFIG= STORAGE_SMOKE_TEST=true STORAGE_ENDPOINT= STORAGE_REGION=us-east-1 STORAGE_BUCKET_PRIVATE=BUCKET_PRIVADO_REAL STORAGE_PATH_STYLE=false ./mvnw -B -Dtest=AlmacenS3RemoteTest test
```

Antes de ese comando, retira `STORAGE_ACCESS_KEY_ID` y `STORAGE_SECRET_ACCESS_KEY` de R2 de la terminal e inyecta las credenciales AWS temporales o el perfil autorizado mediante la cadena estándar del SDK. No las imprimas ni pegues en chats. La prueba escribe/borra únicamente su objeto `_checks/`; por el versionado S3, quedan versiones históricas y un marcador de borrado. No ejecuta operaciones sobre objetos de negocio. Esta comprobación del operador no sustituye comprobar acceso desde el contenedor del API con su rol EC2.

## 3. Publicar assets

El API actual guarda referencias públicas; no crea ni sube automáticamente fotos de hotel o catálogos. Usa una identidad de operador con acceso únicamente al bucket público del entorno correspondiente. No guardes archivos privados en ese bucket.

- R2: sube por el panel o una herramienta S3 usando el endpoint R2 y credenciales de subida limitadas al bucket público.
- S3: sube al `public_bucket` con un perfil AWS de operador autorizado; CloudFront los sirve mediante OAC. No actives ACL `public-read` ni deshabilites el bloqueo público.
- Guarda las URLs bajo `public_assets_url` con la clave del objeto, por ejemplo `.../hotel/fachada.jpg`. Configurar la URL base no sustituye objetos ni reescribe URLs absolutas existentes. Prefiere claves nuevas al reemplazar imágenes para evitar caché antigua de CloudFront.

CORS solo permite GET/HEAD desde los orígenes configurados; las cargas pasan por backend u operador. No se habilitan cargas anónimas del navegador.

### Fotos de habitaciones: publicación y uso en la web

Las fotos se publican con una identidad AWS de operador. La web recibe únicamente
la URL HTTPS de CloudFront; no necesita credenciales AWS ni acceso al bucket.
El API actual admite referencias públicas, pero no tiene un endpoint de subida de
fotos de habitaciones: `/api/v1/archivos/imagenes` admite solamente incidencias.

Desde la raíz de infra, con el checkout de web en una carpeta hermana, revisa
primero las operaciones previstas. Sustituye `BUCKET_PUBLICO` por la salida
`public_bucket` y adapta la ruta si los repositorios están en otra ubicación:

```bash
aws s3 sync ../web/public/images/catalogo-aprobado/ s3://BUCKET_PUBLICO/images/catalogo-aprobado/ --region us-east-1 --exclude '*' --include '*.jpg' --cache-control 'public,max-age=31536000,immutable' --dryrun
# Después de revisar las cargas, repite sin --dryrun.
```

No añadas `--delete`: publicar fotos nuevas no debe borrar las anteriores.
Los nombres deben cambiar al reemplazar el contenido, ya que se cachean como
inmutables durante un año. Subir una foto no registra automáticamente una oferta
ni modifica referencias del API o la web.

Comprueba una foto por ambos caminos, sustituyendo los marcadores por las salidas
y una clave publicada. Los resultados esperados son `200` vía CDN y `403` anónimo
directo en S3:

```bash
curl -I https://DOMINIO_CLOUDFRONT/images/catalogo-aprobado/FOTO.jpg
curl -I https://BUCKET_PUBLICO.s3.us-east-1.amazonaws.com/images/catalogo-aprobado/FOTO.jpg
```

La referencia que consume la web es
`public_assets_url + /images/catalogo-aprobado/FOTO.jpg`. En páginas conectadas al
API, guarda/consume esa URL en el catálogo correspondiente. Las páginas que aún
usan `/images/catalogo-aprobado/...` o Unsplash necesitan actualizar sus
referencias en una PR de web antes de retirar los archivos locales. Crear el CDN
no cambia esas páginas ni sus despliegues.

## 4. Retirar la instalación anterior

- [ ] Si hay objetos útiles en MinIO o en el adaptador `local` de PostgreSQL, cópialos al destino manteniendo las claves y revisa las URLs guardadas antes de retirar el servicio.
- [ ] El nuevo Compose no declara MinIO ni `minio-init`. Detén y retira esos contenedores antiguos únicamente después de conservar lo necesario (`down --remove-orphans` sobre su proyecto correspondiente); no borres volúmenes durante la transición.
- [ ] No hay migración automática de archivos ni de URLs. El arranque no elimina el volumen anterior ni lo traslada a la nube.
- [ ] Mantén las credenciales de pruebas limitadas a R2 dev. Nunca pruebes fixtures SQL ni catálogos ficticios contra producción.

La aplicación usa el AWS SDK existente, con región `auto`, endpoint R2 y cargas sin chunked encoding en dev; S3 usa región nativa y credenciales estándar. Referencias: [R2 con Java](https://developers.cloudflare.com/r2/examples/aws/aws-sdk-java/), [credenciales R2](https://developers.cloudflare.com/r2/api/tokens/), [cadena de credenciales AWS](https://docs.aws.amazon.com/sdk-for-java/latest/developer-guide/credentials-chain.html), [CloudFront OAC](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html).
