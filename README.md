# Globomatics - CloudFormation con stacks anidados

| Archivo | Qué crea |
|---|---|
| `main.yaml` | Stack padre: une los hijos y expone las salidas |
| `red.yaml` | VPC propia, subred pública, Internet Gateway y rutas |
| `seguridad.yaml` | Security Groups de Frontend y Backend |
| `servidor.yaml` | Una EC2 con nginx; se reutiliza para Frontend y Backend |
| `bucket2.yaml` | Bucket S3 privado donde se suben las plantillas hijas |
| `desplegar.sh` | Ejecuta bucket → `package` → `deploy` |

## Seguridad aplicada

- SSH (22) solo desde tu IP (`CidrSsh`, el script la detecta sola). Nunca `0.0.0.0/0`.
- Backend no expuesto: HTTP solo desde el Security Group del Frontend.
- IMDSv2 obligatorio y disco EBS cifrado (gp3) en las instancias.
- Bucket S3 con acceso público bloqueado, cifrado, versionado y solo HTTPS.

## Desplegar

Los `TemplateURL` relativos (`red.yaml`, …) solo funcionan después de
`aws cloudformation package`, que sube los hijos a S3. Por eso no se usa Git sync.

```bash
aws login
./desplegar.sh
```

Otro ambiente: `AMBIENTE=prod ./desplegar.sh`. Región por defecto: `us-east-2`.
El par de claves `rsa-ssh-modulo2` debe existir en esa región.

## Borrar

```bash
aws cloudformation delete-stack --region us-east-2 --stack-name globomatics-dev-app
```
