# Plan de proyecto — mex-open-data-aws-s3

Hoja de ruta para llevar la infraestructura Terraform a un estado profesional, seguro y colaborativo.

---

## Estado actual

- 4 módulos funcionales: S3, IAM, Glue, Athena
- Estado de Terraform almacenado localmente (no compartible)
- Sin `.gitignore`, sin CI/CD, sin tests, IAM con permisos más amplios de lo necesario

---

## 🔴 Semana 1 — Seguridad y estabilidad

Sin estos ítems el estado de Terraform puede corromperse o filtrarse.

- [x] Crear `.gitignore` — excluir `terraform.tfvars`, `.terraform/`, `*.tfstate`, `*.tfstate.*`, `crash.log`, `*.tfplan`
- [x] Añadir `backend "s3" {}` en `main.tf` para almacenar estado remotamente con DynamoDB para state locking — prerequisito para colaboración en equipo
- [x] Restringir `Resource` en la política Glue de IAM al ARN específico del crawler (`arn:aws:glue:*:*:crawler/mex-open-data-*`) en lugar de `"*"`
- [x] Eliminar `s3:DeleteObject` del rol pipeline sobre `curated/` — el pipeline solo escribe en `curated/`, nunca debe borrar
- [x] Habilitar S3 server access logging hacia un prefijo `logs/` en el mismo bucket para auditoría de acceso

---

## 🟠 Semana 2 — Operabilidad y observabilidad

Para detectar fallos de infraestructura sin revisión manual.

- [x] Crear CloudWatch alarm para fallos del Glue crawler (EventBridge rule en `modules/monitoring/main.tf` — más fiable que métricas CW para crawlers)
- [x] Crear CloudWatch alarm para errores 4xx/5xx en S3 (`aws_s3_bucket_metric` + `aws_cloudwatch_metric_alarm`)
- [x] Añadir SNS topic y suscripción de email para recibir alertas de los alarms anteriores
- [x] Añadir `aws_cloudtrail` apuntando al bucket para auditoría completa de cambios de infraestructura
- [x] Añadir variable `glue_schedule` (default `"cron(0 12 ? * MON-FRI *)"`) para cambiar el horario sin tocar el módulo

---

## 🟡 Semana 3 — Calidad de código y CI/CD

- [ ] Crear `.github/workflows/ci.yml`:
  - `terraform fmt -check` en cada push/PR
  - `terraform validate` con provider inicializado
  - `tflint` con reglas de AWS
  - `terraform plan` en PR (salida como comentario automático)
- [ ] Crear `.pre-commit-config.yaml` con: `terraform fmt`, `tflint`, `detect-secrets`
- [ ] Crear `.tflint.hcl` habilitando el plugin de AWS con reglas de naming y deprecaciones
- [ ] Añadir `validation {}` a las variables:
  - `environment`: solo `"dev"` o `"prod"`
  - `bucket_name_prefix`: máximo 30 caracteres, solo minúsculas y guiones
- [ ] Crear `terraform.tfvars` por entorno: `envs/dev.tfvars`, `envs/prod.tfvars`

---

## 🟢 Semana 4 — Madurez y documentación

- [ ] Escribir README completo: arquitectura con diagrama ASCII, prerrequisitos, pasos de despliegue, descripción de outputs, troubleshooting
- [ ] Añadir `README.md` por módulo (`modules/s3/README.md`, etc.) con descripción, inputs y outputs en formato tabla
- [ ] Crear `Makefile` con: `make init`, `make plan`, `make apply`, `make destroy`, `make fmt`, `make validate`
- [ ] Ampliar tagging strategy: añadir `Owner`, `CostCenter`, `DataClassification = "public"` a `local.common_tags`
- [ ] Añadir `terraform test` básico (Terraform 1.6+) para validar que el módulo S3 crea bucket con cifrado habilitado

---

## Orden de implementación

```
1. Seguridad (semana 1)       → .gitignore, remote backend, IAM restrictivo, S3 logging
2. Observabilidad (semana 2)  → CloudWatch alarms, SNS, CloudTrail, variable de schedule
3. CI/CD y calidad (semana 3) → workflows, pre-commit, tflint, validaciones, envs/
4. Madurez (semana 4)         → README, módulos documentados, Makefile, tagging, tests
```
