# Auto Spend Tracker

An intelligent expense tracking system that automatically captures bank SMS messages (Kotak Bank), prompts users for transaction details via notifications, and stores data in a cloud database. Built with Flutter (frontend) and FastAPI (backend).

## 🎯 Features

### Frontend (Flutter)
- 📱 **Automatic SMS Detection**: Background listener for Kotak Bank SMS
- 🔔 **Smart Notifications**: WhatsApp-style inline reply for transaction details
- 📊 **Transaction Dashboard**: Beautiful UI with expandable transaction cards
- ✏️ **Manual Entry**: Add transactions manually for testing
- 🔄 **Real-time Sync**: Instant backend synchronization with success notifications

### Backend (FastAPI)
- 🚀 **Fast API**: RESTful endpoints for transaction management
- 🗄️ **NeonDB Integration**: PostgreSQL database with async support
- 🔍 **Smart Parsing**: Extracts amount, date, UPI ID, account info from SMS
- 📄 **Pagination**: Efficient data fetching for large transaction lists
- 📝 **Auto Documentation**: Swagger UI at `/docs`

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    KOTAK BANK SMS                           │
│  "Sent Rs.236.00 from Kotak Bank AC X0396 to               │
│   vyapar.172400950852@hdfcbank on 05-07-25..."             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Flutter App (Frontend)                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  SMS Listener Service                                 │  │
│  │  - Detects "kotak" sender                            │  │
│  │  - Parses amount & transaction type                  │  │
│  └───────────────────┬───────────────────────────────────┘  │
│                      ▼                                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Notification Service                                 │  │
│  │  - Shows notification with inline reply              │  │
│  │  - Captures user input: "mom, apples"                │  │
│  └───────────────────┬───────────────────────────────────┘  │
│                      ▼                                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  API Service                                          │  │
│  │  - Sends SMS + user input to backend                 │  │
│  │  - Receives success/error response                   │  │
│  └───────────────────┬───────────────────────────────────┘  │
└────────────────────┼─────────────────────────────────────────┘
                     │ HTTP POST
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              FastAPI Backend                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  /api/transactions POST Endpoint                      │  │
│  │  - Receives: {sms_text, user_input}                  │  │
│  └───────────────────┬───────────────────────────────────┘  │
│                      ▼                                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  SMS Parser                                           │  │
│  │  - Extracts: amount, date, type, UPI/account         │  │
│  └───────────────────┬───────────────────────────────────┘  │
│                      ▼                                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  User Input Parser                                    │  │
│  │  - Splits "mom, apples" → person: mom, reason: apples│  │
│  └───────────────────┬───────────────────────────────────┘  │
│                      ▼                                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Database (NeonDB - PostgreSQL)                       │  │
│  │  Stores: date, time, amount, type, person, reason,   │  │
│  │          UPI/account, full_text, sms_text            │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                     │ Success/Error
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Flutter App                                     │
│  - Shows success notification                                │
│  - Refreshes transaction list                                │
│  - Displays transaction in table                             │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Database Schema

### `transactions` Table

| Column                  | Type      | Description                           |
|-------------------------|-----------|---------------------------------------|
| `id`                    | Integer   | Primary key (auto-increment)          |
| `date`                  | String    | Transaction date (DD-MM-YY)           |
| `time`                  | String    | Transaction time (if available)       |
| `amount`                | Float     | Transaction amount                    |
| `transaction_type`      | String    | 'sent' or 'received'                  |
| `sender_receiver_info`  | String    | UPI ID or account number              |
| `applicable_to`         | String    | Person (from user input)              |
| `reason`                | String    | Reason (from user input)              |
| `full_text`             | Text      | Complete user input                   |
| `sms_text`              | Text      | Original bank SMS message             |
| `created_at`            | DateTime  | Timestamp when record was created     |

## 🚀 Quick Start

### 1. Clone Repository

```powershell
git clone https://github.com/anushgr/auto-spend-tracker.git
cd auto-spend-tracker
```

### 2. Setup Backend

```powershell
cd backend

# Create virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Configure database
cp .env.example .env
# Edit .env and add your NeonDB connection string

# Run server
uvicorn main:app --reload
```

Backend will run at: http://localhost:8000

### 3. Setup Frontend

```powershell
cd ../frontend

# Install dependencies
flutter pub get

# Update API URL in lib/services/api_service.dart
# For emulator: http://10.0.2.2:8000
# For device: http://YOUR_COMPUTER_IP:8000

# Run app
flutter run
```

## 📱 Usage

### Automatic Mode (Real Usage)

1. Install app on Android device
2. Grant SMS and notification permissions
3. Wait for Kotak Bank SMS
4. Notification appears with inline reply
5. Type: `person, reason` (e.g., "mom, apples")
6. Submit
7. Success notification appears
8. Transaction visible in app

### Manual Testing Mode

1. Open app
2. Tap **"Add Manual"** FAB
3. Enter SMS text (sample provided)
4. Enter user input: `mom, apples`
5. Tap Submit
6. View transaction in list

### Example SMS Format

```
Sent Rs.236.00 from Kotak Bank AC X0396 to vyapar.172400950852@hdfcbank on 05-07-25.UPI Ref 555256646612. Not you, https://kotak.com/KBANKT/Fraud
```

### User Input Format

```
person, reason
```

Examples:
- `mom, groceries`
- `dad, fuel`
- `self, shopping`
- `friend, dinner`

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.0+**: Cross-platform mobile framework
- **Dart**: Programming language
- **telephony**: SMS reading and listening
- **flutter_local_notifications**: Rich notifications with inline reply
- **http**: REST API client
- **permission_handler**: Runtime permissions
- **shared_preferences**: Local storage

### Backend
- **Python 3.8+**: Programming language
- **FastAPI**: Modern web framework
- **SQLAlchemy**: ORM with async support
- **asyncpg**: PostgreSQL async driver
- **Pydantic**: Data validation
- **Uvicorn**: ASGI server

### Database
- **NeonDB**: Serverless PostgreSQL (cloud)
- **PostgreSQL 14+**: Relational database

## 📂 Project Structure

```
auto-spend-tracker/
├── frontend/                    # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart           # Main app & UI
│   │   └── services/
│   │       ├── api_service.dart          # Backend API client
│   │       ├── notification_service.dart # Notifications
│   │       └── sms_service.dart          # SMS listener
│   ├── android/                # Android-specific config
│   ├── pubspec.yaml            # Flutter dependencies
│   └── README.md               # Frontend docs
│
├── backend/                    # FastAPI server
│   ├── main.py                 # FastAPI app & routes
│   ├── models.py               # SQLAlchemy models
│   ├── schemas.py              # Pydantic schemas
│   ├── database.py             # Database connection
│   ├── parser.py               # SMS & input parsing
│   ├── requirements.txt        # Python dependencies
│   └── README.md               # Backend docs
│
└── README.md                   # This file
```

## 🔧 Configuration

### Frontend Configuration

Edit `frontend/lib/services/api_service.dart`:

```dart
static const String baseUrl = 'YOUR_BACKEND_URL';
```

### Backend Configuration

Edit `backend/.env`:

```env
DATABASE_URL=postgresql+asyncpg://user:pass@host/db?sslmode=require
PORT=8000
```

## 🧪 Testing

### Test Backend API

```powershell
# Health check
curl http://localhost:8000/health

# Create transaction
curl -X POST http://localhost:8000/api/transactions/ \
  -H "Content-Type: application/json" \
  -d '{
    "sms_text": "Sent Rs.236.00 from Kotak Bank AC X0396...",
    "user_input": "mom, apples"
  }'

# Get transactions
curl http://localhost:8000/api/transactions/?page=1&page_size=10
```

### Test Frontend

1. Use Android Emulator's SMS tool (Extended Controls > Phone > SMS)
2. Send test SMS from `AX-KOTAK-S`
3. Check notification appears
4. Use inline reply feature
5. Verify in app's transaction list

## 📊 API Endpoints

### POST /api/transactions/
Create new transaction

**Request:**
```json
{
  "sms_text": "Sent Rs.236.00 from Kotak Bank...",
  "user_input": "mom, apples"
}
```

**Response (201):**
```json
{
  "id": 1,
  "date": "05-07-25",
  "amount": 236.0,
  "transaction_type": "sent",
  "sender_receiver_info": "vyapar.172400950852@hdfcbank",
  "applicable_to": "mom",
  "reason": "apples",
  "full_text": "mom, apples",
  "sms_text": "Sent Rs.236.00...",
  "created_at": "2025-10-22T10:30:00"
}
```

### GET /api/transactions/
Fetch transactions with pagination

**Query Params:**
- `page`: Page number (default: 1)
- `page_size`: Items per page (default: 50, max: 100)

**Response (200):**
```json
{
  "transactions": [...],
  "total": 150,
  "page": 1,
  "page_size": 50
}
```

### GET /api/transactions/{id}
Get single transaction by ID

## 🐛 Troubleshooting

### SMS Not Detected
- Verify sender contains "kotak" (case-insensitive)
- Check SMS permissions granted
- Check logs: `flutter logs` or `adb logcat`

### Backend Connection Error
- Ensure backend is running: `http://localhost:8000/health`
- For emulator: Use `10.0.2.2:8000` not `localhost:8000`
- For device: Use computer's IP address (e.g., `192.168.1.5:8000`)
- Check firewall allows port 8000

### Database Connection Error
- Verify NeonDB credentials in `.env`
- Check internet connection
- Ensure connection string has `sslmode=require`

### Notifications Not Working
- Android 13+: Grant POST_NOTIFICATIONS permission
- Check notification settings for app
- Some manufacturers restrict background notifications

## 🚢 Deployment

### Backend (Production)

1. Deploy to cloud platform (Heroku, Railway, DigitalOcean, AWS)
2. Set environment variables
3. Use production database URL
4. Enable HTTPS

### Frontend (Production)

1. Build release APK:
   ```powershell
   flutter build apk --release
   ```
2. Sign APK for Play Store
3. Update API URL to production backend
4. Test on multiple devices

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Authors

- **Anush GR** - [anushgr](https://github.com/anushgr)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- FastAPI for the lightning-fast backend framework
- NeonDB for serverless PostgreSQL
- Kotak Bank for consistent SMS formats

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Check documentation in `frontend/README.md` and `backend/README.md`
- Review troubleshooting sections

---

**Built with ❤️ using Flutter & FastAPI**
