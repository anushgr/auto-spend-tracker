# Quick Start Guide - Auto Spend Tracker

Follow these steps to get the application running in 10 minutes.

## Step 1: Setup Backend (5 minutes)

### Windows PowerShell

```powershell
# Navigate to backend folder
cd backend

# Create virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Setup NeonDB (get free account at neon.tech)
# Copy and edit .env file
cp .env.example .env
notepad .env
```

**Edit `.env` file:**
```env
DATABASE_URL=postgresql+asyncpg://YOUR_USERNAME:YOUR_PASSWORD@YOUR_NEON_HOST/neondb?sslmode=require
```

Get your NeonDB connection string from: https://console.neon.tech

**Run backend:**
```powershell
uvicorn main:app --reload
```

✅ Backend running at: http://localhost:8000
✅ API docs at: http://localhost:8000/docs

---

## Step 2: Setup Frontend (5 minutes)

### Configure Backend URL

Open `frontend/lib/services/api_service.dart` and update:

```dart
// For Android Emulator (recommended for testing)
static const String baseUrl = 'http://10.0.2.2:8000';

// For Physical Android Device (replace with your computer's IP)
// Find your IP: ipconfig (look for IPv4 Address)
static const String baseUrl = 'http://192.168.1.XXX:8000';
```

### Run Flutter App

```powershell
cd frontend
flutter pub get
flutter run
```

---

## Step 3: Test the Flow

### Option A: Manual Testing (Recommended First)

1. App opens on your device/emulator
2. Grant SMS and notification permissions when prompted
3. Tap the **"Add Manual"** floating action button (bottom-right)
4. Pre-filled SMS text appears (you can modify it)
5. Enter user input: `mom, apples`
6. Tap **Submit**
7. ✅ Success notification appears
8. 📊 Transaction appears in the list

### Option B: Test with SMS (Emulator)

1. Open Android Emulator
2. Click **⋮** (Extended Controls) on emulator toolbar
3. Go to **Phone** > **SMS**
4. Enter:
   - **Sender:** `AX-KOTAK-S`
   - **Message:** `Sent Rs.236.00 from Kotak Bank AC X0396 to vyapar.172400950852@hdfcbank on 05-07-25.UPI Ref 555256646612.`
5. Click **Send Message**
6. 🔔 Notification appears with inline reply
7. In notification, type: `mom, apples`
8. Tap send icon in notification
9. ✅ Success notification appears
10. 📊 Check app - transaction is there!

---

## Common Issues & Fixes

### ❌ Backend: ModuleNotFoundError
```powershell
pip install -r requirements.txt
```

### ❌ Backend: Database connection error
- Check your NeonDB connection string in `.env`
- Ensure it includes `?sslmode=require`
- Verify you have internet connection

### ❌ Frontend: Connection refused (Android Emulator)
- Use `http://10.0.2.2:8000` NOT `http://localhost:8000`
- Emulator's localhost is different from your computer's localhost

### ❌ Frontend: Connection refused (Physical Device)
- Find your computer's IP address: `ipconfig`
- Look for "IPv4 Address" (e.g., 192.168.1.5)
- Update `baseUrl` to `http://YOUR_IP:8000`
- Ensure phone and computer are on same WiFi network
- Check Windows Firewall allows port 8000

### ❌ Notification not showing
- Grant notification permission in app settings
- For Android 13+: App requests POST_NOTIFICATIONS permission
- Check Do Not Disturb is off

### ❌ SMS not detected
- Grant SMS permissions in app settings
- Test with emulator SMS tool first
- Ensure sender contains "kotak" (case-insensitive)

---

## Architecture Flow

```
📱 Kotak SMS arrives
    ↓
🔊 Flutter SMS Listener detects it
    ↓
🔔 Shows notification with inline reply
    ↓
✍️ User types: "mom, apples"
    ↓
🌐 Sends to Backend API (POST /api/transactions)
    ↓
🧠 Backend parses SMS + user input
    ↓
💾 Saves to NeonDB (PostgreSQL)
    ↓
✅ Returns success to Flutter
    ↓
🔔 Success notification shown
    ↓
📊 Transaction list refreshes
```

---

## What's Next?

1. **Test on real device**: Build APK and install on your phone
   ```powershell
   flutter build apk --release
   flutter install
   ```

2. **Add real data**: Wait for actual Kotak Bank SMS or use manual entry

3. **Customize**: 
   - Change UI colors/theme
   - Add filters and search
   - Export to Excel/CSV
   - Add charts and analytics

4. **Deploy**:
   - Backend: Deploy to Railway, Heroku, or DigitalOcean
   - Frontend: Publish to Google Play Store

---

## Need Help?

- Check main `README.md` for detailed documentation
- Check `backend/README.md` for backend-specific docs
- Check `frontend/README.md` for frontend-specific docs
- Open an issue on GitHub

---

**🎉 You're all set! Happy tracking!**
