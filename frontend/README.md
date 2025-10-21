# Frontend (Flutter)

Flutter mobile app for Auto Spend Tracker that automatically detects Kotak Bank SMS messages, prompts users for transaction details via notifications, and syncs with the FastAPI backend.

## Features

- 🔔 **Automatic SMS Detection**: Listens for Kotak Bank SMS messages in background
- 📱 **Inline Reply Notifications**: WhatsApp-style notifications with text input
- 🔄 **Real-time Sync**: Sends transaction data to backend and displays success/error notifications
- 📊 **Transaction Table**: Beautiful UI showing all transactions with expandable details
- ✏️ **Manual Entry**: Add transactions manually for testing
- 🔐 **Permissions Handling**: Automatic SMS and notification permission requests

## Prerequisites

- Flutter SDK 3.0+ installed
- Android device or emulator (API level 23+)
- Backend API running (see `backend/README.md`)

## Installation

### 1. Install Dependencies

```powershell
cd frontend
flutter pub get
```

### 2. Configure Backend URL

Edit `lib/services/api_service.dart` and update the `baseUrl`:

```dart
// For Android emulator (backend on local machine):
static const String baseUrl = 'http://10.0.2.2:8000';

// For physical device (replace with your computer's IP):
static const String baseUrl = 'http://192.168.x.x:8000';

// For production:
static const String baseUrl = 'https://your-backend.com';
```

### 3. Run the App

```powershell
# For Android device/emulator
flutter run

# For debugging
flutter run --debug

# For release build
flutter build apk --release
```

## How It Works

### 1. SMS Detection Flow

1. **Incoming SMS**: App listens for SMS from senders containing "kotak" (AX-KOTAK-S, VM-KOTAK, etc.)
2. **Parse Amount**: Extracts transaction amount and type (sent/received)
3. **Show Notification**: Displays notification with amount and inline reply field
4. **User Input**: User types details in format: `person, reason` (e.g., "mom, apples")
5. **Send to Backend**: App sends SMS text + user input to FastAPI backend
6. **Result Notification**: Shows success/error notification
7. **Refresh UI**: Transaction appears in the app's table

### 2. UI Components

#### Home Screen
- **Transaction List**: Shows all transactions with expandable cards
- **Refresh Button**: Reload data from backend
- **Manual Entry FAB**: Add test transactions

#### Transaction Card
- **Summary View**: Person, reason, amount, date
- **Expanded View**: Full details including SMS text, UPI ID, etc.
- **Color Coding**: Green for received, red for sent

## Permissions Required

The app requests these permissions on first launch:

- `RECEIVE_SMS`: Listen to incoming SMS
- `READ_SMS`: Read SMS content
- `READ_PHONE_STATE`: Access phone state
- `POST_NOTIFICATIONS`: Show notifications (Android 13+)
- `INTERNET`: Connect to backend API

## Testing

### Test with Manual Entry

1. Open the app
2. Tap the **"Add Manual"** floating button
3. Enter sample SMS text (pre-filled example provided)
4. Enter user input like: `mom, apples`
5. Tap **Submit**
6. Check for success notification
7. Transaction appears in the list

### Test with Simulated SMS (Emulator)

1. Open Android Emulator
2. In Extended Controls (⋮), go to **Phone** > **SMS**
3. Enter sender: `AX-KOTAK-S`
4. Enter message:
   ```
   Sent Rs.236.00 from Kotak Bank AC X0396 to vyapar.172400950852@hdfcbank on 05-07-25.UPI Ref 555256646612.
   ```
5. Click **Send Message**
6. Notification should appear with inline reply
7. Type: `mom, apples` and submit
8. Transaction saved!

### Test on Real Device

1. Build and install APK on your Android phone:
   ```powershell
   flutter build apk --release
   flutter install
   ```
2. Grant all permissions when prompted
3. Wait for a real Kotak Bank SMS or use the manual entry feature

## File Structure

```
frontend/
├── lib/
│   ├── main.dart                    # Main app entry, UI, and home screen
│   └── services/
│       ├── api_service.dart         # Backend API calls (POST/GET transactions)
│       ├── notification_service.dart # Notification handling and inline replies
│       └── sms_service.dart         # SMS listener and parser
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml      # Permissions and receivers
├── pubspec.yaml                     # Dependencies
└── README.md                        # This file
```

## Dependencies

- `telephony: ^0.2.0` - SMS reading and listening
- `flutter_local_notifications: ^17.2.3` - Rich notifications with inline reply
- `http: ^1.2.2` - HTTP requests to backend
- `permission_handler: ^11.3.1` - Runtime permission requests
- `shared_preferences: ^2.3.2` - Local data storage

## Troubleshooting

### SMS Not Detected
- Check permissions: Settings > Apps > Auto Spend Tracker > Permissions
- Ensure SMS sender contains "kotak" (case-insensitive)
- Check logs: `flutter logs` or `adb logcat`

### Notifications Not Showing
- Android 13+: Must request POST_NOTIFICATIONS permission
- Check notification settings for the app
- Enable "Allow notification access" in system settings

### Backend Connection Failed
- Verify backend is running: `http://localhost:8000/health`
- Check `baseUrl` in `api_service.dart`
- For emulator: Use `10.0.2.2` not `localhost`
- For device: Use computer's local IP address
- Disable firewall or allow port 8000

### Inline Reply Not Working
- Feature requires Android 7.0+ (API 24+)
- Check notification channel settings
- Some manufacturers (Xiaomi, Oppo) restrict background notifications

## API Configuration

Update `lib/services/api_service.dart`:

```dart
class ApiService {
  static const String baseUrl = 'YOUR_BACKEND_URL';
  // ...
}
```

## Building for Production

### Release APK

```powershell
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### App Bundle (for Google Play)

```powershell
flutter build appbundle --release
```

### Signing Configuration

Edit `android/app/build.gradle` and add signing configs for production.

## Notes

- The app runs in background and automatically detects SMS
- Battery optimization may stop background SMS listening on some devices
- For production, whitelist your app in battery optimization settings
- Inline reply feature is Android-specific; iOS uses different notification APIs

## Next Steps

- [ ] Add filtering/sorting in transaction list
- [ ] Export transactions to CSV/Excel
- [ ] Add charts and analytics
- [ ] Support multiple bank SMS formats
- [ ] Add biometric authentication
- [ ] Implement offline caching
