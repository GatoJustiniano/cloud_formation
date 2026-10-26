#!/usr/bin/env bash
# Despliega los stacks anidados: crea el bucket, sube las plantillas hijas y despliega main.yaml.
# Uso: ./desplegar.sh            (dev por defecto)
#      AMBIENTE=prod ./desplegar.sh
set -euo pipefail
cd "$(dirname "$0")"

PROYECTO="${PROYECTO:-globomatics}"
AMBIENTE="${AMBIENTE:-dev}"
TIPO_INSTANCIA="${TIPO_INSTANCIA:-t3.micro}"
REGION="${REGION:-us-east-2}"

CUENTA="$(aws sts get-caller-identity --query Account --output text)"
BUCKET="${PROYECTO}-${AMBIENTE}-${CUENTA}"
MI_IP="$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]')"

echo "1/3 Bucket de plantillas: ${BUCKET}"
aws cloudformation deploy --region "$REGION" \
  --template-file bucket2.yaml \
  --stack-name "${PROYECTO}-${AMBIENTE}-bucket" \
  --parameter-overrides "Proyecto=${PROYECTO}" "Ambiente=${AMBIENTE}" \
  --no-fail-on-empty-changeset

echo "2/3 Subiendo plantillas hijas a S3"
aws cloudformation package --region "$REGION" \
  --template-file main.yaml \
  --s3-bucket "$BUCKET" \
  --s3-prefix plantillas \
  --output-template-file main.empaquetado.yaml

echo "3/3 Desplegando stack principal (SSH permitido solo desde ${MI_IP}/32)"
aws cloudformation deploy --region "$REGION" \
  --template-file main.empaquetado.yaml \
  --stack-name "${PROYECTO}-${AMBIENTE}-app" \
  --parameter-overrides "Proyecto=${PROYECTO}" "Ambiente=${AMBIENTE}" \
    "TipoInstancia=${TIPO_INSTANCIA}" "CidrSsh=${MI_IP}/32" \
  --no-fail-on-empty-changeset

aws cloudformation describe-stacks --region "$REGION" \
  --stack-name "${PROYECTO}-${AMBIENTE}-app" \
  --query "Stacks[0].Outputs" --output table
