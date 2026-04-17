# Flutter App - Cloud Run Backend Update

This document summarizes the changes made to connect your Flutter app to the Cloud Run backend.

## ✅ Changes Made

### 1. API Endpoint Updated

**File**: `lib/utils/constants.dart`

**Before** (localhost):
```dart
static const String baseUrl = 'http://localhost:8000/api';
```

**After** (Cloud Run):
```dart
static const String baseUrl = 'https://YOUR-SERVICE-URL.run.app/api';
```

---

## 🔒 Security Improvements

✅ **HTTPS enabled** - All API calls now use secure HTTPS (provided by Cloud Run)
✅ **No cleartext traffic** - Removed need for Android cleartext traffic permissions
✅ **SSL certificate** - Automatic SSL certificate from Google Cloud

---

## 🧪 Testing the App

### 1. Clean and Rebuild

```bash
# Clean the project
flutter clean

# Get dependencies
flutter pub get

# Run on device/emulator
flutter run
```

### 2. Test Authentication

1. **Register** a new account
   - Backend URL: `https://YOUR-SERVICE-URL.run.app/api/auth/register`
   - Should create account and return JWT token

2. **Login** with the account
   - Backend URL: `https://YOUR-SERVICE-URL.run.app/api/auth/login`
   - Should authenticate and load home screen

### 3. Test Recording & Transcription

1. **Record audio** from home screen
   - Tap microphone FAB
   - Record a conversation with contact information
   - Stop recording

2. **Transcribe audio**
   - Should upload to Cloud Run backend
   - OpenAI Whisper will transcribe
   - GPT-4 will extract contact info
   - New contact should appear in list

### 4. Test Contact Management

1. **View contacts** - List should load from Cloud Run
2. **View details** - Tap contact to see full information
3. **Share contact** - Test WhatsApp/Email sharing
4. **Delete contact** - Delete and verify sync

---

---

## 📱 Platform-Specific Notes

### Android
- ✅ **HTTPS works out of the box** - No special configuration needed
- ✅ **Internet permission** - Already configured in AndroidManifest.xml
- ✅ **SSL certificates** - Trusted by default (Google's SSL)

### iOS
- ✅ **HTTPS works out of the box** - No App Transport Security (ATS) exceptions needed
- ✅ **Network permissions** - Already configured
- ✅ **SSL certificates** - Trusted by default

---

## 🔄 Switching Between Environments

If you want to switch between local and production:

### For Local Development (Docker):
```dart
static const String baseUrl = 'http://localhost:8000/api';
// or for Android emulator:
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

### For Production (Cloud Run):
```dart
static const String baseUrl = 'https://YOUR-SERVICE-URL.run.app/api';
```

**Tip**: You can use Flutter flavors or environment variables to switch between dev/prod automatically.

---

## 🐛 Troubleshooting

### "Network error" or "Connection refused"

**Check**:
1. Internet connection on device
2. Backend is running: https://YOUR-SERVICE-URL.run.app/health
3. Firewall/VPN not blocking requests

**Solution**:
```bash
# Test backend from terminal
curl https://YOUR-SERVICE-URL.run.app/health

# Should return: {"status":"healthy"}
```

### "401 Unauthorized" on protected endpoints

**Cause**: JWT token expired or not sent

**Solution**:
1. Logout and login again
2. Check token is stored in FlutterSecureStorage
3. Verify Authorization header is sent: `Bearer <token>`

### "500 Internal Server Error"

**Check backend logs**:
```bash
gcloud run services logs read YOUR-SERVICE-NAME --region YOUR-REGION --limit 50
```

Common causes:
- Database connection issue
- OpenAI API key issue
- Invalid request data

### Audio upload fails

**Check**:
1. Audio file size (Cloud Run has 32MB request limit)
2. Audio format (should be .m4a or .wav)
3. Backend timeout (set to 300s = 5 minutes)

**Solution**:
- Keep recordings under 10 minutes
- Check internet connection during upload
- View backend logs for detailed error

---

## 📊 Backend Monitoring

View Cloud Run metrics:
```bash
# Open Cloud Run Console
https://console.cloud.google.com/run/detail/YOUR-REGION/YOUR-SERVICE-NAME

# View logs
gcloud run services logs tail YOUR-SERVICE-NAME --region YOUR-REGION

# Check metrics
- Request count
- Latency
- Error rate
- Container instances
```

---

## 🎯 Next Steps

1. ✅ **Test thoroughly** - Try all features with Cloud Run backend
2. 📱 **Test on real device** - Not just emulator
3. 🌐 **Test network conditions** - Try slow/unstable connections
4. 🔐 **Security review** - Ensure sensitive data is protected
5. 📈 **Monitor usage** - Check Cloud Run metrics and costs

---

## ✨ Benefits of Cloud Run Backend

✅ **Always available** - No need to run Docker locally
✅ **Scalable** - Auto-scales with usage
✅ **Secure** - HTTPS by default
✅ **Fast** - Google's global network
✅ **Cost-efficient** - Pay only for actual usage
✅ **Production-ready** - Same setup for dev and prod

---

## 📝 Summary

Your Flutter app now connects to:
- **Production Backend**: https://YOUR-SERVICE-URL.run.app
- **Database**: Supabase PostgreSQL (cloud)
- **AI Services**: OpenAI Whisper + GPT-4
- **Storage**: Cloud Run /tmp (ephemeral)

All communication is **encrypted with HTTPS** and **production-ready**! 🎉
