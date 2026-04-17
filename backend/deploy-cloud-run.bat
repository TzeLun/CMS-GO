@echo off
REM CMS-GO Backend - Cloud Run Deployment Script (Windows)
REM This script builds and deploys your backend to Google Cloud Run

echo === CMS-GO Backend - Cloud Run Deployment ===
echo.

REM Check if gcloud is installed
where gcloud >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: gcloud CLI is not installed
    echo Install from: https://cloud.google.com/sdk/docs/install
    exit /b 1
)

REM Get project ID
set /p PROJECT_ID="Enter your GCP Project ID: "
if "%PROJECT_ID%"=="" (
    echo Error: Project ID cannot be empty
    exit /b 1
)

REM Set project
echo.
echo Setting GCP project...
gcloud config set project %PROJECT_ID%

REM Get region
echo.
echo Select deployment region:
echo 1) asia-southeast1 (Singapore)
echo 2) us-central1 (Iowa)
echo 3) europe-west1 (Belgium)
set /p REGION_CHOICE="Choice [1]: "
if "%REGION_CHOICE%"=="" set REGION_CHOICE=1

if "%REGION_CHOICE%"=="1" set REGION=asia-southeast1
if "%REGION_CHOICE%"=="2" set REGION=us-central1
if "%REGION_CHOICE%"=="3" set REGION=europe-west1

echo Using region: %REGION%

REM Get environment variables
echo.
set /p DATABASE_URL="Enter your Supabase DATABASE_URL: "
echo.
set /p SECRET_KEY="Enter your SECRET_KEY (JWT signing key): "
echo.
set /p OPENAI_API_KEY="Enter your OPENAI_API_KEY: "

REM Confirm details
echo.
echo === Deployment Summary ===
echo Project ID: %PROJECT_ID%
echo Region: %REGION%
echo Image: gcr.io/%PROJECT_ID%/cms-backend
echo.
set /p PROCEED="Proceed with deployment? (y/n): "

if /i not "%PROCEED%"=="y" (
    echo Deployment cancelled
    exit /b 0
)

REM Enable required APIs
echo.
echo Enabling required Google Cloud APIs...
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.gcr.io
gcloud services enable cloudbuild.googleapis.com

REM Build and push image
echo.
echo Building and pushing Docker image...
gcloud builds submit --tag gcr.io/%PROJECT_ID%/cms-backend

if %errorlevel% neq 0 (
    echo Error: Docker build failed
    exit /b 1
)

REM Deploy to Cloud Run
echo.
echo Deploying to Cloud Run...
gcloud run deploy cms-backend ^
  --image gcr.io/%PROJECT_ID%/cms-backend ^
  --platform managed ^
  --region %REGION% ^
  --allow-unauthenticated ^
  --set-env-vars="DATABASE_URL=%DATABASE_URL%" ^
  --set-env-vars="SECRET_KEY=%SECRET_KEY%" ^
  --set-env-vars="OPENAI_API_KEY=%OPENAI_API_KEY%" ^
  --memory 2Gi ^
  --cpu 2 ^
  --timeout 300 ^
  --max-instances 10 ^
  --min-instances 0

if %errorlevel% equ 0 (
    echo.
    echo === Deployment Successful! ===
    echo.
    echo Getting service URL...
    for /f "delims=" %%i in ('gcloud run services describe cms-backend --region=%REGION% --format="value(status.url)"') do set SERVICE_URL=%%i

    echo Service URL: %SERVICE_URL%
    echo.
    echo API Endpoints:
    echo   - Health: %SERVICE_URL%/health
    echo   - API Docs: %SERVICE_URL%/docs
    echo   - Base API: %SERVICE_URL%/api
    echo.
    echo Next Steps:
    echo 1. Update your Flutter app's baseUrl to: %SERVICE_URL%/api
    echo 2. Visit API docs: %SERVICE_URL%/docs
    echo 3. Test endpoints via Swagger UI
    echo 4. Monitor logs: gcloud run services logs tail cms-backend --region=%REGION%
) else (
    echo Deployment failed. Check logs above for errors.
    exit /b 1
)

echo.
pause
