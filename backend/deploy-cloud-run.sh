#!/bin/bash

# CMS-GO Backend - Cloud Run Deployment Script
# This script builds and deploys your backend to Google Cloud Run

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== CMS-GO Backend - Cloud Run Deployment ===${NC}\n"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Get project ID
echo -e "${YELLOW}Enter your GCP Project ID:${NC}"
read -r PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: Project ID cannot be empty${NC}"
    exit 1
fi

# Set project
echo -e "\n${GREEN}Setting GCP project...${NC}"
gcloud config set project "$PROJECT_ID"

# Get region
echo -e "\n${YELLOW}Select deployment region:${NC}"
echo "1) asia-southeast1 (Singapore)"
echo "2) us-central1 (Iowa)"
echo "3) europe-west1 (Belgium)"
echo "4) Custom"
read -r -p "Choice [1]: " REGION_CHOICE
REGION_CHOICE=${REGION_CHOICE:-1}

case $REGION_CHOICE in
    1) REGION="asia-southeast1" ;;
    2) REGION="us-central1" ;;
    3) REGION="europe-west1" ;;
    4)
        echo -e "${YELLOW}Enter custom region:${NC}"
        read -r REGION
        ;;
    *) REGION="asia-southeast1" ;;
esac

echo -e "${GREEN}Using region: $REGION${NC}"

# Get environment variables
echo -e "\n${YELLOW}Enter your Supabase DATABASE_URL:${NC}"
read -r -p "DATABASE_URL: " DATABASE_URL

echo -e "\n${YELLOW}Enter your SECRET_KEY (JWT signing key):${NC}"
read -r -p "SECRET_KEY: " SECRET_KEY

echo -e "\n${YELLOW}Enter your OPENAI_API_KEY:${NC}"
read -r -p "OPENAI_API_KEY: " OPENAI_API_KEY

# Confirm details
echo -e "\n${YELLOW}=== Deployment Summary ===${NC}"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Image: gcr.io/$PROJECT_ID/cms-backend"
echo "Database: ${DATABASE_URL:0:50}..."
echo "Secret Key: ${SECRET_KEY:0:20}..."
echo "OpenAI Key: ${OPENAI_API_KEY:0:20}..."

echo -e "\n${YELLOW}Proceed with deployment? (y/n)${NC}"
read -r -p "Choice: " PROCEED

if [[ ! $PROCEED =~ ^[Yy]$ ]]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 0
fi

# Enable required APIs
echo -e "\n${GREEN}Enabling required Google Cloud APIs...${NC}"
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.gcr.io
gcloud services enable cloudbuild.googleapis.com

# Build and push image
echo -e "\n${GREEN}Building and pushing Docker image...${NC}"
gcloud builds submit --tag "gcr.io/$PROJECT_ID/cms-backend"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Docker build failed${NC}"
    exit 1
fi

# Deploy to Cloud Run
echo -e "\n${GREEN}Deploying to Cloud Run...${NC}"
gcloud run deploy cms-backend \
  --image "gcr.io/$PROJECT_ID/cms-backend" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --set-env-vars="DATABASE_URL=$DATABASE_URL" \
  --set-env-vars="SECRET_KEY=$SECRET_KEY" \
  --set-env-vars="OPENAI_API_KEY=$OPENAI_API_KEY" \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --max-instances 10 \
  --min-instances 0

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}=== Deployment Successful! ===${NC}"

    # Get service URL
    SERVICE_URL=$(gcloud run services describe cms-backend --region="$REGION" --format="value(status.url)")

    echo -e "\n${GREEN}Service URL: $SERVICE_URL${NC}"
    echo -e "\n${YELLOW}Testing deployment...${NC}"

    # Test health endpoint
    HEALTH_CHECK=$(curl -s "$SERVICE_URL/health")

    if [[ $HEALTH_CHECK == *"healthy"* ]]; then
        echo -e "${GREEN}✓ Health check passed${NC}"
        echo -e "\n${GREEN}API Endpoints:${NC}"
        echo "  - Health: $SERVICE_URL/health"
        echo "  - API Docs: $SERVICE_URL/docs"
        echo "  - Base API: $SERVICE_URL/api"

        echo -e "\n${YELLOW}Next Steps:${NC}"
        echo "1. Update your Flutter app's baseUrl to: $SERVICE_URL/api"
        echo "2. Visit API docs: $SERVICE_URL/docs"
        echo "3. Test endpoints via Swagger UI"
        echo "4. Monitor logs: gcloud run services logs tail cms-backend --region=$REGION"
    else
        echo -e "${YELLOW}⚠ Health check failed, but service is deployed${NC}"
        echo "Check logs: gcloud run services logs read cms-backend --region=$REGION"
    fi

else
    echo -e "${RED}Deployment failed. Check logs above for errors.${NC}"
    exit 1
fi
