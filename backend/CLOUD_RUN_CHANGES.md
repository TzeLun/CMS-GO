# Cloud Run Compatibility Changes Summary

This document summarizes the changes made to make CMS-GO backend compatible with Google Cloud Run.

## Changes Made

### 1. Dockerfile Updated ✓
**File**: `Dockerfile`

**Changes**:
- Removed `--reload` flag (production-ready)
- Updated CMD to use Cloud Run's `PORT` environment variable
- Removed `/app/uploads` directory creation (using `/tmp` instead)

**Before**:
```dockerfile
RUN mkdir -p /app/uploads
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

**After**:
```dockerfile
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
```

**Why**: Cloud Run provides dynamic `PORT` environment variable. Falls back to 8000 for local development.

---

### 2. File Uploads Changed to /tmp ✓
**File**: `app/main.py`

**Changes**:
- Changed upload directory from `"uploads"` to `"/tmp"`

**Before**:
```python
upload_dir = "uploads"
```

**After**:
```python
upload_dir = "/tmp"
```

**Why**:
- Cloud Run has read-only filesystem except `/tmp`
- `/tmp` is ephemeral storage (up to container's memory limit)
- Files are automatically cleaned up in `finally` block
- Works for both local and Cloud Run environments

---

### 3. .dockerignore Added ✓
**File**: `.dockerignore` (new)

**Purpose**:
- Optimize Docker build by excluding unnecessary files
- Reduce image size
- Faster builds

**Excludes**:
- Python cache files (`__pycache__`, `*.pyc`)
- Virtual environments
- `.env` files (secrets should use Secret Manager)
- Documentation files
- IDE configs
- Git files
- Local `uploads/` directory

---

### 4. Deployment Documentation Added ✓
**File**: `CLOUD_RUN_DEPLOYMENT.md` (new)

**Contents**:
- Step-by-step deployment guide
- Environment variable setup
- Secret Manager configuration
- Resource recommendations
- Troubleshooting tips
- Production checklist

---

## Environment Variables for Cloud Run

### Required:
```bash
DATABASE_URL=postgresql://YOUR_DB_USER:YOUR_DB_PASSWORD@YOUR_DB_HOST:5432/YOUR_DB_NAME
SECRET_KEY=<your-jwt-secret>
OPENAI_API_KEY=<your-openai-key>
```

### NOT Required:
- `API_HOST` - Cloud Run handles this
- `API_PORT` - Cloud Run provides `PORT` variable
- `postgres_data` volume - Using Supabase
- `uploads_data` volume - Using `/tmp`

---

## Local vs Cloud Run Behavior

| Feature | Local (Docker Compose) | Cloud Run |
|---------|------------------------|-----------|
| Port | 8000 (hardcoded) | Dynamic via `$PORT` (usually 8080) |
| File uploads | `/tmp` | `/tmp` |
| Database | Supabase | Supabase |
| Secrets | `.env` file | Secret Manager (recommended) |
| Volumes | Not used | N/A |
| Auto-scaling | Single container | 0-10+ instances |

---

## Testing Locally

The changes are fully backward compatible with local development:

```bash
# Build and run locally
cd cms
docker-compose build backend
docker-compose up -d backend

# Test health endpoint
curl http://localhost:8000/health

# Test API docs
open http://localhost:8000/docs
```

---

## Deployment Quick Start

```bash
# 1. Build and push to GCP
cd cms/backend
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/cms-backend

# 2. Deploy to Cloud Run
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

# 3. Test deployment
curl https://YOUR-SERVICE-URL.run.app/health
```

---

## Benefits

✅ **Cloud Run Compatible**: Works seamlessly on Google Cloud Run
✅ **Backward Compatible**: Still works locally with Docker Compose
✅ **Ephemeral Storage**: Uses `/tmp` for temporary files (auto-cleanup)
✅ **Dynamic Port**: Supports Cloud Run's dynamic port assignment
✅ **Production Ready**: No reload, optimized build
✅ **Scalable**: Auto-scales from 0 to N instances
✅ **Cost Efficient**: Pay only for actual usage

---

## Files Modified

1. ✅ `Dockerfile` - Updated CMD for Cloud Run
2. ✅ `app/main.py` - Changed upload dir to `/tmp`
3. ✅ `.dockerignore` - Added (new)
4. ✅ `CLOUD_RUN_DEPLOYMENT.md` - Added (new)
5. ✅ `CLOUD_RUN_CHANGES.md` - This file (new)

---

## Next Steps

1. **Test locally** - Ensure everything works
2. **Set up GCP project** - Enable required APIs
3. **Create secrets** - Use Secret Manager for sensitive data
4. **Deploy to Cloud Run** - Follow deployment guide
5. **Update Flutter app** - Point to Cloud Run URL
6. **Monitor and optimize** - Set up logging and monitoring

---

## Important Notes

⚠️ **File Storage**: Files in `/tmp` are lost when container restarts. This is acceptable for audio transcription since files are processed and deleted immediately.

⚠️ **Memory Limits**: `/tmp` storage counts against container memory. For large audio files, ensure adequate memory allocation (2Gi recommended).

⚠️ **Cold Starts**: First request after idle period may be slower. Set `--min-instances 1` to avoid cold starts at the cost of higher billing.

⚠️ **Timeout**: Audio transcription may take time. Set appropriate timeout (300s = 5 minutes).

---

## Support

For detailed deployment instructions, see `CLOUD_RUN_DEPLOYMENT.md`
