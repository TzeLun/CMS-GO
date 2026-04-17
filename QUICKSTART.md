# Quick Start Guide

This guide will help you get the Contact Management System up and running in 5 minutes.

## Prerequisites

Ensure you have:
- Flutter SDK installed
- Docker Desktop installed and running
- OpenAI API key (get one from https://platform.openai.com/api-keys)

## Step 1: Configure Backend (2 minutes)

1. Navigate to the backend directory:
```bash
cd cms/backend
```

2. Create environment file:
```bash
cp .env.example .env
```

3. Edit `.env` and add your OpenAI API key:
```env
OPENAI_API_KEY=sk-your-api-key-here
```

## Step 2: Start Backend (1 minute)

From the `cms` directory:

```bash
docker-compose up -d
```

Wait for services to start. Verify with:

```bash
docker-compose ps
```

Both services should show "Up" or "healthy".

## Step 3: Run Flutter App (2 minutes)

1. Install dependencies:
```bash
cd cms
flutter pub get
```

2. Run the app:
```bash
flutter run
```

## Step 4: Test the App

1. **Register**: Create a new account
2. **Record**: Tap the Record button and test recording
3. **View Contacts**: See your contacts on the home screen

## Stopping the Services

To stop the backend:

```bash
cd cms
docker-compose down
```

## Troubleshooting

**Backend not starting?**
```bash
docker-compose down
docker-compose up --build -d
```

**Flutter dependencies error?**
```bash
flutter clean
flutter pub get
```

**Can't connect to backend from app?**
- For Android Emulator: Use `http://10.0.2.2:8000/api` in `lib/utils/constants.dart`
- For iOS Simulator: Use `http://localhost:8000/api`
- For Physical Device: Use your computer's IP address (e.g., `http://192.168.1.100:8000/api`)

## Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Access API docs at http://localhost:8000/docs
- Customize the UI to match your branding

## Support

If you encounter issues:
1. Check backend logs: `docker-compose logs backend`
2. Check database logs: `docker-compose logs db`
3. Verify OpenAI API key is valid
4. Ensure ports 8000 and 5432 are not in use

---

**Happy developing! 🚀**
