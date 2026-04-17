# Cloud Run Deployment Guide for CMS-GO Backend

This guide explains how to deploy your CMS-GO backend to Google Cloud Run.

## Prerequisites

1. **Google Cloud Project** with billing enabled
2. **gcloud CLI** installed and authenticated
3. **Docker** installed locally (for testing)
4. **APIs enabled**:
   - Cloud Run API
   - Container Registry API or Artifact Registry API
   - Cloud Build API

## Step 1: Configure gcloud CLI

```bash
# Login to Google Cloud
gcloud auth login

# Set your project ID
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.gcr.io
gcloud services enable cloudbuild.googleapis.com
```

## Step 2: Build and Push Docker Image

### Option A: Using Cloud Build (Recommended)

```bash
# Navigate to backend directory
cd cms/backend

# Build and push to Google Container Registry
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/cms-backend

# Or use Artifact Registry (newer)
gcloud builds submit --tag asia-southeast1-docker.pkg.dev/YOUR_PROJECT_ID/cms-repo/cms-backend
```

### Option B: Build Locally and Push

```bash
# Build the image
docker build -t gcr.io/YOUR_PROJECT_ID/cms-backend .

# Authenticate Docker with GCR
gcloud auth configure-docker

# Push to GCR
docker push gcr.io/YOUR_PROJECT_ID/cms-backend
```

## Step 3: Deploy to Cloud Run

### Basic Deployment

```bash
gcloud run deploy cms-backend \
  --image gcr.io/YOUR_PROJECT_ID/cms-backend \
  --platform managed \
  --region asia-southeast1 \
  --allow-unauthenticated \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --max-instances 10 \
  --min-instances 0
```

### With Environment Variables (Inline)

```bash
gcloud run deploy cms-backend \
  --image gcr.io/YOUR_PROJECT_ID/cms-backend \
  --platform managed \
  --region asia-southeast1 \
  --allow-unauthenticated \
  --set-env-vars="DATABASE_URL=postgresql://YOUR_DB_USER:YOUR_DB_PASSWORD@YOUR_DB_HOST:5432/YOUR_DB_NAME" \
  --set-env-vars="SECRET_KEY=YOUR_JWT_SECRET_KEY" \
  --set-env-vars="OPENAI_API_KEY=sk-proj-YOUR-KEY-HERE" \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300
```

### With Secret Manager (Recommended for Production)

**First, create secrets:**

```bash
# Create DATABASE_URL secret
echo -n "postgresql://YOUR_DB_USER:YOUR_DB_PASSWORD@YOUR_DB_HOST:5432/YOUR_DB_NAME" | \
  gcloud secrets create supabase-db-url --data-file=-

# Create SECRET_KEY secret
echo -n "YOUR_JWT_SECRET_KEY" | \
  gcloud secrets create jwt-secret-key --data-file=-

# Create OPENAI_API_KEY secret
echo -n "sk-proj-YOUR-KEY-HERE" | \
  gcloud secrets create openai-api-key --data-file=-
```

**Then deploy with secrets:**

```bash
gcloud run deploy cms-backend \
  --image gcr.io/YOUR_PROJECT_ID/cms-backend \
  --platform managed \
  --region asia-southeast1 \
  --allow-unauthenticated \
  --set-secrets="DATABASE_URL=supabase-db-url:latest" \
  --set-secrets="SECRET_KEY=jwt-secret-key:latest" \
  --set-secrets="OPENAI_API_KEY=openai-api-key:latest" \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300
```

## Step 4: Verify Deployment

After deployment, Cloud Run will provide a service URL like:
```
https://cms-backend-RANDOM-HASH-uc.a.run.app
```

Test the deployment:

```bash
# Test health endpoint
curl https://YOUR-SERVICE-URL.run.app/health

# Test API docs
open https://YOUR-SERVICE-URL.run.app/docs
```

## Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | ✅ Yes | Supabase PostgreSQL connection string |
| `SECRET_KEY` | ✅ Yes | JWT token signing key |
| `OPENAI_API_KEY` | ✅ Yes | OpenAI API key for Whisper/GPT-4 |
| `PORT` | ❌ No | Auto-set by Cloud Run (default: 8080) |

**Note:**
- `API_HOST` and `API_PORT` are NOT needed on Cloud Run
- Cloud Run automatically provides `PORT` environment variable
- Your Dockerfile is configured to use `${PORT:-8000}`

## Resource Configuration

Recommended settings for production:

```bash
--memory 2Gi              # 2GB RAM (adjust based on usage)
--cpu 2                   # 2 vCPUs (adjust based on usage)
--timeout 300             # 5 minutes (for long transcriptions)
--max-instances 10        # Auto-scale up to 10 instances
--min-instances 0         # Scale to zero when idle (save costs)
--concurrency 80          # Max concurrent requests per instance
```

For high-traffic scenarios:
```bash
--min-instances 1         # Keep 1 instance always running (reduce cold starts)
--max-instances 20        # Higher max instances
```

## Cost Optimization

1. **Scale to Zero**: Set `--min-instances 0` to avoid charges when idle
2. **Request-based Billing**: Only pay for actual usage
3. **Use Secrets Manager**: Avoid exposing sensitive data
4. **Monitor Costs**: Set up billing alerts in GCP Console

## Updating the Service

To deploy updates:

```bash
# Rebuild and push new image
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/cms-backend

# Deploy the update (Cloud Run will automatically use latest image)
gcloud run deploy cms-backend \
  --image gcr.io/YOUR_PROJECT_ID/cms-backend \
  --platform managed \
  --region asia-southeast1
```

## Monitoring and Logs

View logs:
```bash
# Stream logs
gcloud run services logs tail cms-backend --region asia-southeast1

# View in Cloud Console
https://console.cloud.google.com/run
```

## Custom Domain (Optional)

Map your own domain:

```bash
# Add domain mapping
gcloud run domain-mappings create \
  --service cms-backend \
  --domain api.yourdomain.com \
  --region asia-southeast1
```

Then update your DNS records as instructed by Cloud Run.

## Flutter App Configuration

Update your Flutter app's API endpoint:

```dart
// In constants.dart
static const String baseUrl = 'https://YOUR-SERVICE-URL.run.app/api';
```

## Troubleshooting

### Container fails to start
```bash
# Check logs
gcloud run services logs read cms-backend --region asia-southeast1 --limit 50

# Common issues:
# 1. Missing environment variables
# 2. Database connection issues
# 3. Port binding (ensure using ${PORT})
```

### 503 Service Unavailable
- Check if service is deployed: `gcloud run services list`
- Verify memory/CPU limits aren't too low
- Check application startup logs

### Database connection errors
- Verify DATABASE_URL is correct
- Check if Supabase allows connections from Cloud Run IPs
- Ensure using Transaction Pooler (port 6543)

## Security Best Practices

1. ✅ **Use Secret Manager** for sensitive credentials
2. ✅ **Enable HTTPS** (automatic on Cloud Run)
3. ✅ **Set up IAM** for production deployments
4. ✅ **Use VPC Connector** for private database access (if needed)
5. ✅ **Enable Cloud Armor** for DDoS protection (if needed)

## Production Checklist

- [ ] Environment variables configured via Secret Manager
- [ ] Custom domain mapped
- [ ] Monitoring and alerting set up
- [ ] Backup strategy for database
- [ ] Rate limiting configured (if needed)
- [ ] CORS settings verified
- [ ] SSL certificate working
- [ ] Load testing completed
- [ ] Cost alerts configured
- [ ] Documentation updated with production URL

## Support

- **Cloud Run Docs**: https://cloud.google.com/run/docs
- **Pricing**: https://cloud.google.com/run/pricing
- **Quotas**: https://cloud.google.com/run/quotas
