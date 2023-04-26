#!/bin/bash

set -eu
set -x

# Set variables
PROJECT_ID="cabakuru-analytics"
REGION="asia-northeast1"
POSTGRES_USER="redash_user"
POSTGRES_PASSWORD="redash_password"
POSTGRES_DB="redash_db"
REDASH_COOKIE_SECRET="b94e8bd0ec961625d5c589da7da987c8"
REDASH_THROTTLE_LOGIN_PATTERN=1000/hour
VPC_CONNECTOR="my-vpc-connector"
REPOSITORY_NAME="redash"
CLOUD_SQL_INSTANCE_NAME="redash"
REDIS_INSTANCE_NAME="redash"
PROJECT_NUMBER=791369243901
SERVICE_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
IMAGE_URL="$REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY_NAME/redash:latest"

# Get private IPs of Cloud SQL and Redis instances
get_cloud_sql_private_ip() {
  gcloud sql instances describe $1 --format=json | jq -r '.ipAddresses[] | select(.type=="PRIVATE") | .ipAddress'
}

get_redis_private_ip() {
  gcloud redis instances describe $1 --region=$2 --format="value(host)"
}

CLOUD_SQL_PRIVATE_IP=$(get_cloud_sql_private_ip $CLOUD_SQL_INSTANCE_NAME)
REDIS_PRIVATE_IP=$(get_redis_private_ip $REDIS_INSTANCE_NAME $REGION)

# Set URLs and log level
REDIS_URL="redis://$REDIS_PRIVATE_IP:6379/0"
REDASH_DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${CLOUD_SQL_PRIVATE_IP}:5432/${POSTGRES_DB}"
REDASH_LOG_LEVEL=INFO
#REDASH_LOG_LEVEL=DEBUG

# Configure Docker client to authenticate with Artifact Registry
gcloud config set project ${PROJECT_ID}
gcloud auth configure-docker $REGION-docker.pkg.dev

# Build and push Docker image to Artifact Registry
docker build --progress=plain -t $IMAGE_URL .
docker push $IMAGE_URL

# Deploy Redash services to Cloud Run
ENV_VARS="REDIS_URL=$REDIS_URL,REDASH_COOKIE_SECRET=$REDASH_COOKIE_SECRET,REDASH_DATABASE_URL=$REDASH_DATABASE_URL,REDASH_LOG_LEVEL=${REDASH_LOG_LEVEL},REDASH_FEATURE_SHOW_SETTINGS_SAML_LOGIN=true,REDASH_THROTTLE_LOGIN_PATTERN=${REDASH_THROTTLE_LOGIN_PATTERN}"
COMMON_ARGS=(
  "--image" "$IMAGE_URL"
  "--region" "$REGION"
  "--set-env-vars" "$ENV_VARS"
  "--service-account" "${SERVICE_ACCOUNT}"
  "--vpc-connector" "$VPC_CONNECTOR"
  "--cpu" "2"
  "--memory" "8Gi"
)

#gcloud beta run jobs deploy redash-init "${COMMON_ARGS[@]}" --tasks 1 --command=./bin/docker-entrypoint,manage,database,create_tables --execute-now
gcloud beta run deploy redash "${COMMON_ARGS[@]}" --platform managed --port 5000 --allow-unauthenticated --cpu-throttling --execution-environment=gen2
gcloud beta run jobs deploy redash-worker "${COMMON_ARGS[@]}" --tasks 1 --command=./bin/docker-entrypoint,worker --execute-now
gcloud beta run jobs deploy redash-scheduler "${COMMON_ARGS[@]}" --tasks 1 --command=./bin/docker-entrypoint,scheduler --execute-now
