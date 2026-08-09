# Terraform — LiteThinking

Práctica de aprovisionamiento de infraestructura en AWS con Terraform.

```text
Terraform/
├── .github/workflows/ # Pipeline: fmt/validate + SAST (tfsec) + plan + apply (aprobación manual), por rama = ambiente
├── modules/            # Módulos reutilizables (sin provider ni state propio)
│   ├── s3/              # Bucket S3 + objeto opcional
│   ├── lambda/           # Función Lambda (IAM role + empaquetado zip)
│   └── ecs/               # Demo ECS Fargate (repo ECR, cluster, task def, ALB, service)
└── infra/                # Único root module desplegable (bucket + Lambda + demo ECS Fargate)
    └── envs/               # dev.tfvars / uat.tfvars / prod.tfvars — un mismo código, tres ambientes
```

`infra/` es el **único proyecto que se despliega** (`terraform init/plan/apply` se ejecutan ahí). Los módulos en `modules/` no tienen `provider.tf` ni state propio — son plantillas que `infra/main.tf` invoca con `source = "../modules/..."`. Nuevos componentes (ej. una API, una cola SQS, ECS) se agregan como módulos nuevos en `modules/` e instancias nuevas dentro de `infra/main.tf`, no como carpetas raíz independientes.

## 1. Prerequisitos

- **Terraform** instalado y en el `PATH`. Verificar:

  ```powershell
  terraform version
  ```

- **AWS CLI v2** con el profile `mae` configurado. Verificar:

  ```powershell
  aws sts get-caller-identity --profile mae
  ```

  Debe devolver el `Account` e `Arn` de la cuenta, sin error.

## 2. Backend remoto (setup inicial, una sola vez)

`infra/` guarda su state en un bucket S3 (`infra/backend.tf`) en vez de en disco — así el pipeline de CI, que corre en runners efímeros, puede leer/escribir siempre el mismo state. Ese bucket **no lo gestiona Terraform**: se crea a mano, para evitar el problema de huevo-y-gallina (Terraform necesitaría un backend para guardar el state del backend que está creando) y para que un `destroy` futuro nunca pueda llevarse por delante el propio bucket de state.

```powershell
aws s3api create-bucket --bucket <nombre-unico-del-bucket> --region us-east-1 --profile mae
aws s3api put-bucket-versioning --bucket <nombre-unico-del-bucket> --versioning-configuration Status=Enabled --profile mae
aws s3api put-bucket-encryption --bucket <nombre-unico-del-bucket> --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' --profile mae
aws s3api put-public-access-block --bucket <nombre-unico-del-bucket> --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true --profile mae
```

Con el bucket creado, reemplazar el nombre de bucket en `infra/backend.tf` por el real (hoy: `terraform-states-07082026`), y migrar el state local existente si aplica:

```powershell
$env:AWS_PROFILE = "mae"
cd infra
terraform init -migrate-state
```

No se agregó DynamoDB para locking: el gate de aprobación manual en CI ya serializa los `apply` (uno a la vez) — ver "Próximos pasos".

## 3. Ambientes (`dev` / `uat` / `prod`)

Un mismo código (`infra/`), tres ambientes aislados vía **Terraform workspaces** — cada uno con su propio state (dentro del mismo bucket, sin configurar nada extra) y sus propios valores (`envs/<ambiente>.tfvars`): nombre de bucket, de función Lambda y tag `Environment` distintos, para que no choquen entre sí.

```powershell
$env:AWS_PROFILE = "mae"
cd infra
terraform workspace select dev || terraform workspace new dev   # crea el workspace la primera vez
terraform plan  -var-file="envs/dev.tfvars"
terraform apply -var-file="envs/dev.tfvars"
```

Para `uat` o `prod`, mismo flujo cambiando `dev` por el nombre del ambiente en los tres comandos (`workspace`, `-var-file`, y el nombre del `.tfvars`). `terraform workspace show` dice en cuál estás parado — revisarlo siempre antes de un `apply`, para no aplicar el `.tfvars` de un ambiente sobre el workspace de otro.

> **Si ya habías aplicado `infra/` antes** de que existieran los ambientes (workspace `default`, sin sufijo en `bucket_name`): ese deployment quedó fuera de este esquema. Antes de usar `dev`/`uat`/`prod` por primera vez, hacé `terraform workspace select default` y `terraform destroy` ahí, para no dejarlo corriendo (y facturando) sin que ningún ambiente lo gestione.

## 4. Cómo probarlo

**Ver los outputs del ambiente activo:**

```powershell
terraform output
```

**Confirmar que el bucket existe y subir un archivo para disparar la Lambda:**

```powershell
aws s3 ls --profile mae
aws s3 cp algo.txt s3://<bucket_name>/algo.txt --profile mae
```

**Ver los logs de la Lambda invocada:**

```powershell
aws logs tail /aws/lambda/<function_name> --profile mae --follow
```

**Desplegar una imagen en el servicio ECS Fargate del demo:**

El `apply` crea el repo ECR, el cluster, el ALB y el servicio, pero el servicio no queda "sano" hasta que exista una imagen en el tag que espera (`ecs_image_tag`, `latest` por default) — Terraform no construye ni sube imágenes Docker, eso es un paso manual aparte:

```powershell
$repo = terraform output -raw ecs_ecr_repository_url
aws ecr get-login-password --region us-east-1 --profile mae | docker login --username AWS --password-stdin $repo.Split('/')[0]
docker pull nginx:latest
docker tag nginx:latest "${repo}:latest"
docker push "${repo}:latest"
```

El servicio recoge la imagen nueva en el próximo ciclo de despliegue de tareas (o forzarlo con `aws ecs update-service --cluster <ecs_app_name> --service <ecs_app_name> --force-new-deployment --profile mae`). Verificar en el navegador con la URL de `terraform output ecs_alb_dns_name`.

## 5. Cómo destruirlo

```powershell
terraform workspace select <ambiente>   # dev, uat o prod — confirmá con "terraform workspace show"
terraform destroy -var-file="envs/<ambiente>.tfvars"
```

Pide confirmar con `yes`. Elimina bucket, objeto, Lambda, rol IAM, la notificación y todo el demo ECS (repo ECR, cluster, ALB, servicio) **de ese ambiente**; los otros dos quedan intactos. (El bucket de state, al no estar gestionado por Terraform, no se ve afectado.)

> El ALB tiene costo fijo por hora mientras exista — si el demo ECS es solo para práctica puntual, conviene destruirlo cuando no se esté usando en vez de dejarlo corriendo entre sesiones.

## Archivos de `infra/`

| Archivo | Función |
| --- | --- |
| `versions.tf` | Versión mínima de Terraform y providers requeridos (`aws`, `random`, `archive`) |
| `provider.tf` | Región de AWS (credenciales vía `$env:AWS_PROFILE` local o secrets en CI) |
| `backend.tf` | Backend remoto `s3` para el state — ver [Backend remoto](#2-backend-remoto-setup-inicial-una-sola-vez) |
| `variables.tf` | Parámetros sin default (`aws_region` sí trae uno): `bucket_name`, `environment`, `function_name`, `ecs_app_name` — obligan a pasar un `-var-file` (`ecs_image_tag` sí trae default: `latest`) |
| `envs/dev.tfvars`, `envs/uat.tfvars`, `envs/prod.tfvars` | Valores concretos por ambiente — ver [Ambientes](#3-ambientes-dev--uat--prod) |
| `main.tf` | `module "bucket"`, `module "notifier"`, permiso de invocación y notificación S3→Lambda, `module "ecs_app"` (demo Fargate) sobre la VPC default de la cuenta |
| `outputs.tf` | Valores mostrados tras el `apply` |
| `index.html` | Objeto de prueba subido al bucket |
| `src/index.js` | Código fuente de la Lambda (se empaqueta a zip automáticamente) |

## Convenciones

- **Tags**: `main.tf` define `local.common_tags` (`Environment`, `ManagedBy`, `Project`) y se pasa igual a ambos módulos — una sola fuente de verdad en vez de tags sueltos por recurso.
- **Sin `profile` hardcodeado en `provider.tf` ni en `backend.tf`** — el profile es algo local de cada máquina, no algo versionable. Localmente se setea vía `$env:AWS_PROFILE`; en CI llegan credenciales por `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` (secrets de GitHub). Los bloques `backend` además no aceptan variables, así que esto no se puede parametrizar dentro del archivo — tiene que resolverse desde afuera (entorno).
- **`.gitignore`** ignora `*.tfstate`, `.terraform/` y `*.tfvars` en general, salvo `infra/envs/*.tfvars` (config de ambiente, sin secretos) y `*.tfvars.example` — el state y los overrides realmente locales nunca se versionan.
- **`aws_s3_object`** en vez de subir el archivo con `aws s3 cp` — así queda versionado en el estado de Terraform y se re-sube solo si el contenido cambia (usa `filemd5()` como `etag`).

## CI/CD (`.github/workflows/terraform-infra.yml`)

El ambiente a desplegar **depende de la rama destino**, no de un ambiente elegido a mano — modelo de promoción por rama:

```text
feature/x ──PR──▶ dev ──PR──▶ uat ──PR──▶ main
                (dev)       (uat)      (prod)
```

Cada PR o push a `dev`, `uat` o `main` dispara el pipeline; un job `resolve` traduce la rama destino a un ambiente (`dev`→`dev`, `uat`→`uat`, `main`→`prod`) y el resto del pipeline opera sobre ese único ambiente:

1. **`resolve`** — determina el ambiente a partir de la rama (`github.base_ref` en PR, `github.ref_name` en push).
2. **`validate`** — `terraform fmt -check`, `init`, `validate`.
3. **`tfsec`** — escaneo SAST de IaC (aquasecurity/tfsec). Corta el pipeline si encuentra hallazgos.
4. **`plan`** — selecciona el workspace del ambiente resuelto, corre `terraform plan -var-file=envs/<ambiente>.tfvars`, guarda el plan como artefacto y, si es un PR, lo comenta para revisión humana antes de mergear.
5. **`apply`** — **solo en push** (o sea, tras mergear el PR), bajo el GitHub Environment que corresponda al ambiente resuelto. Pide aprobación manual ahí antes de aplicar exactamente el plan del paso 4.

Para promover un cambio a producción, se repite el PR dos veces más: de `dev` a `uat`, y de `uat` a `main` — cada salto vuelve a planear y a pedir aprobación para ese ambiente específico.

### Setup manual en GitHub (una sola vez, no lo puedo hacer yo)

Requiere el repo ya creado (y **público** — ver nota abajo) y con push hecho a GitHub:

1. **Secrets** (`Settings → Secrets and variables → Actions`): agregar `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` de un usuario/rol de AWS con permisos sobre S3, Lambda, IAM (rol de ejecución) y CloudWatch Logs — idealmente un IAM user dedicado al pipeline, no tu perfil personal `mae`. Los tres ambientes comparten las mismas credenciales por ahora (misma cuenta AWS) — ver "Próximos pasos" para separarlas.
2. **Tres ramas**: `dev` y `uat` no existen por defecto — crearlas desde `main` (`git checkout -b dev && git push -u origin dev`, ídem `uat`).
3. **Tres Environments de aprobación** (`Settings → Environments → New environment`, uno por cada nombre: `dev`, `uat`, `prod`): en cada uno, activar **Required reviewers** y agregar quién debe aprobar. Sin esto, el `apply` de ese ambiente corre sin pedir aprobación.
   > "Required reviewers" en repos **privados** solo está disponible con plan GitHub Team/Enterprise — en Free hace falta que el repo sea **público** (Settings → Danger Zone → Change visibility) para que aparezca esa opción.
4. (Opcional, recomendado) **Branch protection** (`Settings → Branches → Add rule`) sobre `dev`, `uat` y `main`: requerir pull request antes de mergear, para que nadie pueda pushear directo saltándose la revisión del `plan`.

## Visualización (opcional)

Requiere **InfraMap** ([releases](https://github.com/cycloidio/inframap/releases)) y **Graphviz** (`dot -V` para verificar), ambos instalados manualmente y agregados al `PATH`.

```powershell
cd infra
inframap generate --raw terraform.tfstate | dot -Tpng -o diagrama-raw.png
```

**Importante:** usar siempre `--raw`. El modo por defecto de InfraMap filtra recursos que no reconoce como "arquitectura de red" (VPCs, EC2, etc.).

## Próximos pasos

- DynamoDB para locking del state, si en algún momento hay applies concurrentes reales (más de un desarrollador, o pipelines paralelos).
- Reemplazar las credenciales estáticas del pipeline (`AWS_ACCESS_KEY_ID`/`SECRET`) por OIDC (GitHub → rol IAM asumido temporalmente, sin secreto de larga duración) — más seguro, algo más de setup inicial.
- Separar `prod` (y quizás `uat`) en su propia cuenta de AWS, con su propio set de credenciales en el pipeline — hoy los tres ambientes comparten cuenta, lo cual es razonable para practicar pero no es el aislamiento real que tendría una prod de verdad.
- El demo ECS usa la VPC default y HTTP plano en el ALB (sin HTTPS/ACM) — suficiente para practicar, pero `tfsec` puede marcar hallazgos (SG `0.0.0.0/0`, listener sin TLS, ECR con tags mutables) que en un caso real habría que resolver antes de producción.
