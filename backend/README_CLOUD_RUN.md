# CMS-GO Backend - Cloud Run Deployment

Quick guide to deploy your CMS-GO backend to Google Cloud Run.

## 🚀 Quick Deploy

### Windows:
```cmd
deploy-cloud-run.bat
```

### Linux/Mac:
```bash
chmod +x deploy-cloud-run.sh
./deploy-cloud-run.sh
```

The script will guide you through the deployment process.

---

## 📋 Prerequisites

1. **Google Cloud Account** with billing enabled
2. **gcloud CLI** installed: https://cloud.google.com/sdk/docs/install
3. **Docker** installed (for local testing)
4. **GCP Project** created

---

## 🔑 Required Information

Have these ready before deploying:

1. **GCP Project ID** - Your Google Cloud project
2. **Supabase DATABASE_URL**:
   ```
   postgresql://YOUR_DB_USER:YOUR_DB_PASSWORD@YOUR_DB_HOST:5432/YOUR_DB_NAME
   ```
3. **SECRET_KEY** - JWT signing key (from `.env`)
4. **OPENAI_API_KEY** - Your OpenAI API key

---

## 📦 What Changed for Cloud Run

### ✅ Changes Made:
- **Dockerfile**: Uses dynamic `PORT` from Cloud Run
- **File uploads**: Changed to `/tmp` (Cloud Run compatible)
- **.dockerignore**: Added for optimized builds
- **No volumes**: Using Supabase (cloud database)

### ❌ What's NOT Needed:
- `API_HOST` - Cloud Run handles this
- `API_PORT` - Cloud Run provides `PORT`
- Local PostgreSQL - Using Supabase
- Docker volumes - Using `/tmp`

---

## 🎯 Manual Deployment Steps

If you prefer manual deployment:

### 1. Build Image
```bash
cd cms/backend
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/cms-backend
```

### 2. Deploy to Cloud Run
```bash
gcloud run deploy cms-backend \
  --image gcr.io/YOUR_PROJECT_ID/cms-backend \
  --platform managed \
  --region asia-southeast1 \
  --allow-unauthenticated \
  --set-env-vars="DATABASE_URL=YOUR_DB_URL" \
  --set-env-vars="SECRET_KEY=YOUR_SECRET" \
  --set-env-vars="OPENAI_API_KEY=YOUR_KEY" \
  --memory 2Gi \
  --timeout 300
```

### 3. Get Service URL
```bash
gcloud run services describe cms-backend --region asia-southeast1 --format="value(status.url)"
```

---

## 🧪 Testing Deployment

After deployment:

```bash
# Test health endpoint
curl https://YOUR-SERVICE-URL.run.app/health

# Open API docs
open https://YOUR-SERVICE-URL.run.app/docs
```

---

## 📱 Update Flutter App

Update your Flutter app's API endpoint:

```dart
// In lib/utils/constants.dart
static const String baseUrl = 'https://YOUR-SERVICE-URL.run.app/api';
```

---

## 💰 Cost Estimation

Cloud Run pricing (as of 2025):

**Free Tier (per month)**:
- 2 million requests
- 360,000 GB-seconds
- 180,000 vCPU-seconds

**Example costs** (after free tier):
- 10,000 requests/month: ~$0.50
- 100,000 requests/month: ~$5
- 1,000,000 requests/month: ~$50

**Tip**: Set `--min-instances 0` to scale to zero when idle = $0 when not in use!

---

## 📊 Monitoring

View logs:
```bash
# Stream logs
gcloud run services logs tail cms-backend --region asia-southeast1

# View in Cloud Console
https://console.cloud.google.com/run
```

---

## 🔒 Security Best Practices

For production, use Secret Manager instead of inline env vars:

```bash
# Create secrets
echo -n "YOUR_DB_URL" | gcloud secrets create supabase-db-url --data-file=-
echo -n "YOUR_SECRET" | gcloud secrets create jwt-secret-key --data-file=-
echo -n "YOUR_KEY" | gcloud secrets create openai-api-key --data-file=-

# Deploy with secrets
gcloud run deploy cms-backend \
  --image gcr.io/YOUR_PROJECT_ID/cms-backend \
  --set-secrets="DATABASE_URL=supabase-db-url:latest" \
  --set-secrets="SECRET_KEY=jwt-secret-key:latest" \
  --set-secrets="OPENAI_API_KEY=openai-api-key:latest"
```

---

## 📚 Documentation

- **Full deployment guide**: `CLOUD_RUN_DEPLOYMENT.md`
- **Changes summary**: `CLOUD_RUN_CHANGES.md`
- **Cloud Run docs**: https://cloud.google.com/run/docs

---

## ⚠️ Important Notes

1. **Files in `/tmp` are ephemeral** - Lost on container restart (OK for audio processing)
2. **Cold starts** - First request after idle may be slower
3. **Timeout** - Set to 300s (5 min) for large audio files
4. **Memory** - 2Gi recommended for audio transcription

---

## 🆘 Troubleshooting

### Deployment fails
```bash
# Check build logs
gcloud builds log VIEW_BUILD_ID

# Check service logs
gcloud run services logs read cms-backend --region asia-southeast1 --limit 50
```

### Service returns 500
- Check environment variables are set correctly
- Verify database connection string
- Check OpenAI API key is valid

### Service returns 503
- Service may not be deployed properly
- Check memory/CPU limits
- View logs for startup errors

---

## ✅ Production Checklist

Before going live:

- [ ] Test all endpoints via Swagger UI
- [ ] Use Secret Manager for credentials
- [ ] Set up custom domain (optional)
- [ ] Configure monitoring alerts
- [ ] Set up billing alerts
- [ ] Test with Flutter app
- [ ] Load test the service
- [ ] Document the production URL

---

## 🎉 Success!

Your backend should now be running on Cloud Run!

**Service URL format**: `https://cms-backend-XXXXX-XX.a.run.app`

Visit the `/docs` endpoint to test your API!
