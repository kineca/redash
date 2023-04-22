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
VPC_CONNECTOR="my-vpc-connector"
REPOSITORY_NAME="redash"

# Get private IP of Cloud SQL instance
CLOUD_SQL_INSTANCE_NAME="redash"
CLOUD_SQL_PRIVATE_IP=$(gcloud sql instances describe $CLOUD_SQL_INSTANCE_NAME --format="value(ipAddresses[?type=PRIVATE].ipAddress)")
CLOUD_SQL_PRIVATE_IP=172.26.96.7

# Get private IP of Redis instance
REDIS_INSTANCE_NAME="redash"
REDIS_PRIVATE_IP=$(gcloud redis instances describe $REDIS_INSTANCE_NAME --region=$REGION --format="value(host)")

REDIS_URL="redis://$REDIS_PRIVATE_IP:6379/0"
REDASH_DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${CLOUD_SQL_PRIVATE_IP}:5432/${POSTGRES_DB}"

# Enable required services
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com

# Configure Docker client to authenticate with Artifact Registry
gcloud config set project ${PROJECT_ID}
gcloud auth configure-docker $REGION-docker.pkg.dev

PROJECT_NUMBER=791369243901
SERVICE_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

#gcloud projects add-iam-policy-binding $PROJECT_ID \
#    --member="serviceAccount:${SERVICE_ACCOUNT}" \
#    --role="roles/artifactregistry.reader"

# Build and push Docker image to Artifact Registry
docker build --progress=plain -t $REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY_NAME/redash:latest .
docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY_NAME/redash:latest

# Deploy Redash service to Cloud Run
gcloud run deploy redash \
    --image asia-northeast1-docker.pkg.dev/cabakuru-analytics/redash/redash:latest \
    --platform managed \
    --use-http2 \
    --region $REGION \
    --port 5000 \
    --allow-unauthenticated \
    --set-env-vars "REDIS_URL=$REDIS_URL,REDASH_COOKIE_SECRET=$REDASH_COOKIE_SECRET,REDASH_DATABASE_URL=$REDASH_DATABASE_URL" \
    --service-account ${SERVICE_ACCOUNT} \
    --vpc-connector $VPC_CONNECTOR \
    --memory 2Gi

gcloud beta run domain-mappings create --service redash --domain redash.pato.today --region $REGION
