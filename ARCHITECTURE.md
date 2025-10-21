# System Architecture - Auto Spend Tracker

## Complete Data Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│                         KOTAK BANK                                    │
│                                                                       │
│  Sends SMS: "Sent Rs.236.00 from Kotak Bank AC X0396 to             │
│              vyapar.172400950852@hdfcbank on 05-07-25..."            │
└────────────────────────────────┬──────────────────────────────────────┘
                                 │ SMS via carrier
                                 ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    ANDROID DEVICE / EMULATOR                          │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  1. SMS Receiver (Background Service)                       │    │
│  │     - Listens for all incoming SMS                          │    │
│  │     - Filters: sender.contains("kotak")                     │    │
│  │     - Active even when app is closed                        │    │
│  └──────────────────────┬──────────────────────────────────────┘    │
│                         │                                             │
│                         ▼                                             │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  2. SMS Parser (lib/services/sms_service.dart)              │    │
│  │     Input:  "Sent Rs.236.00 from Kotak Bank..."            │    │
│  │     Output: { amount: 236.0, type: "sent" }                │    │
│  └──────────────────────┬──────────────────────────────────────┘    │
│                         │                                             │
│                         ▼                                             │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  3. Notification Service (notification_service.dart)        │    │
│  │     Shows: "💸 Money Sent - ₹236.00"                        │    │
│  │     With: Inline reply input box                            │    │
│  │     Stores: SMS text in SharedPreferences                   │    │
│  └──────────────────────┬──────────────────────────────────────┘    │
└────────────────────────┼──────────────────────────────────────────────┘
                         │
                         │ User types: "mom, apples"
                         ▼
┌──────────────────────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  4. User Input Handler                                      │    │
│  │     Retrieves: SMS text from SharedPreferences              │    │
│  │     Combines: SMS + user input                              │    │
│  │     Payload: {                                              │    │
│  │       sms_text: "Sent Rs.236.00...",                        │    │
│  │       user_input: "mom, apples"                             │    │
│  │     }                                                        │    │
│  └──────────────────────┬──────────────────────────────────────┘    │
│                         │                                             │
│                         │ HTTP POST                                   │
│                         ▼                                             │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  5. API Service (api_service.dart)                          │    │
│  │     POST http://10.0.2.2:8000/api/transactions/             │    │
│  │     Headers: { Content-Type: application/json }             │    │
│  │     Body: { sms_text: "...", user_input: "mom, apples" }   │    │
│  └──────────────────────┬──────────────────────────────────────┘    │
└────────────────────────┼──────────────────────────────────────────────┘
                         │
                         │ Over WiFi/Mobile Data
                         ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    FASTAPI BACKEND (Port 8000)                        │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  6. POST /api/transactions/ Endpoint (routes.py)            │    │
│  │     Receives: TransactionCreate schema                      │    │
│  │     Validates: Pydantic model                               │    │
│  └──────────────────────┬──────────────────────────────────────┘    │
│                         │                                             │
│                         ▼                                             │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  7. SMS Parser (parser.py)                                  │    │
│  │     parse_kotak_sms()                                       │    │
│  │     - Regex: Rs\.?(\d+(?:,\d+)*(?:\.\d+)?)  → amount       │    │
│  │     - Regex: (sent|received|debited|credited) → type        │    │
│  │     - Regex: ([\w\.-]+@[\w]+) → UPI ID                      │    │
│  │     - Regex: (\d{2}-\d{2}-\d{2}) → date                     │    │
│  │                                                              │    │
│  │     Output: {                                               │    │
│  │       amount: 236.0,                                        │    │
│  │       transaction_type: "sent",                             │    │
│  │       sender_receiver_info: "vyapar.172400950852@hdfcbank", │    │
│  │       date: "05-07-25"                                      │    │
│  │     }                                                        │    │
│  └──────────────────────┬──────────────────────────────────────┘    │
│                         │                                             │
│                         ▼                                             │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  8. User Input Parser (parser.py)                           │    │
│  │     parse_user_input("mom, apples")                         │    │
│  │     - Split by comma                                        │    │
│  │     - parts[0] = applicable_to = "mom"                      │    │
│  │     - parts[1] = reason = "apples"                          │    │
│  └──────────────────────┬──────────────────────────────────────┘    │
│                         │                                             │
│                         ▼                                             │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  9. Create Transaction Object (models.py)                   │    │
│  │     Transaction(                                            │    │
│  │       date = "05-07-25",                                    │    │
│  │       time = None,                                          │    │
│  │       amount = 236.0,                                       │    │
│  │       transaction_type = "sent",                            │    │
│  │       sender_receiver_info = "vyapar.172400...@hdfcbank",   │    │
│  │       applicable_to = "mom",                                │    │
│  │       reason = "apples",                                    │    │
│  │       full_text = "mom, apples",                            │    │
│  │       sms_text = "Sent Rs.236.00...",                       │    │
│  │       created_at = datetime.utcnow()                        │    │
│  │     )                                                        │    │
│  └──────────────────────┬──────────────────────────────────────┘    │
│                         │                                             │
│                         │ SQLAlchemy async                            │
│                         ▼                                             │
└────────────────────────┼──────────────────────────────────────────────┘
                         │
                         │ PostgreSQL protocol (asyncpg)
                         ▼
┌──────────────────────────────────────────────────────────────────────┐
│                  NEONDB (PostgreSQL Cloud)                            │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  10. INSERT INTO transactions                               │    │
│  │                                                              │    │
│  │  Table: transactions                                        │    │
│  │  ┌────┬───────────┬────────┬────────┬──────────────┐       │    │
│  │  │ id │   date    │ amount │  type  │ applicable_to│       │    │
│  │  ├────┼───────────┼────────┼────────┼──────────────┤       │    │
│  │  │ 1  │ 05-07-25  │ 236.0  │ sent   │ mom          │       │    │
│  │  │ 2  │ 06-07-25  │ 500.0  │ recv'd │ dad          │       │    │
│  │  └────┴───────────┴────────┴────────┴──────────────┘       │    │
│  │                                                              │    │
│  │  + sender_receiver_info, reason, full_text, sms_text,      │    │
│  │    time, created_at columns                                 │    │
│  └──────────────────────┬──────────────────────────────────────┘    │
│                         │                                             │
│                         │ Commit transaction                          │
│                         ▼                                             │
│                    Success / Error                                    │
└────────────────────────┼──────────────────────────────────────────────┘
                         │
                         │ HTTP 201 Created
                         ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    FASTAPI BACKEND                                    │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  11. Return Response                                        │    │
│  │     Status: 201 Created                                     │    │
│  │     Body: {                                                 │    │
│  │       "id": 1,                                              │    │
│  │       "date": "05-07-25",                                   │    │
│  │       "amount": 236.0,                                      │    │
│  │       "transaction_type": "sent",                           │    │
│  │       "sender_receiver_info": "vyapar...@hdfcbank",         │    │
│  │       "applicable_to": "mom",                               │    │
│  │       "reason": "apples",                                   │    │
│  │       "full_text": "mom, apples",                           │    │
│  │       "sms_text": "Sent Rs.236.00...",                      │    │
│  │       "created_at": "2025-10-22T10:30:00"                   │    │
│  │     }                                                        │    │
│  └──────────────────────┬──────────────────────────────────────┘    │
└────────────────────────┼──────────────────────────────────────────────┘
                         │
                         │ JSON Response
                         ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    FLUTTER APP                                        │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  12. API Response Handler (api_service.dart)                │    │
│  │     if (response.statusCode == 201) {                       │    │
│  │       return { success: true, message: "Saved!" }           │    │
│  │     }                                                        │    │
│  └──────────────────────┬──────────────────────────────────────┘    │
│                         │                                             │
│                         ▼                                             │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  13. Show Success Notification                              │    │
│  │     Title: "✅ Transaction Saved"                           │    │
│  │     Message: "Transaction saved successfully!"              │    │
│  └──────────────────────┬──────────────────────────────────────┘    │
│                         │                                             │
│                         ▼                                             │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  14. Refresh Transaction List                               │    │
│  │     GET http://10.0.2.2:8000/api/transactions/?page=1       │    │
│  │     Fetches all transactions from database                  │    │
│  │     Updates UI with latest data                             │    │
│  └──────────────────────┬──────────────────────────────────────┘    │
│                         │                                             │
│                         ▼                                             │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  15. Display in UI (main.dart)                              │    │
│  │     ┌─────────────────────────────────────────────────┐     │    │
│  │     │ 💸 mom                           ₹236.00        │     │    │
│  │     │ apples                                          │     │    │
│  │     │ Sent • 05-07-25                                 │     │    │
│  │     │                                                 │     │    │
│  │     │ [Tap to expand for full details]               │     │    │
│  │     └─────────────────────────────────────────────────┘     │    │
│  └─────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
```

## Technology Stack per Component

| Component | Technology | Purpose |
|-----------|------------|---------|
| SMS Receiver | Android Broadcast Receiver | Listen to incoming SMS in background |
| SMS Parsing | Dart RegEx | Extract amount, type from SMS |
| Notifications | flutter_local_notifications | Show rich notifications with inline reply |
| HTTP Client | Dart http package | REST API communication |
| Backend API | FastAPI + Uvicorn | REST endpoints and async processing |
| Data Validation | Pydantic | Request/response schema validation |
| SMS Parser | Python RegEx | Extract transaction details |
| ORM | SQLAlchemy (async) | Database models and queries |
| Database Driver | asyncpg | PostgreSQL async connection |
| Database | NeonDB (PostgreSQL) | Cloud-hosted persistent storage |

## Security Considerations

1. **SMS Permissions**: Only granted when user approves
2. **API Communication**: Should use HTTPS in production
3. **Database**: NeonDB requires SSL (sslmode=require)
4. **User Data**: Stored securely in PostgreSQL
5. **No Plaintext Storage**: All data encrypted in transit

## Performance

- **SMS Detection**: Instant (broadcast receiver)
- **Notification**: < 1 second
- **API Call**: 100-500ms (depends on network)
- **Database Write**: < 100ms (NeonDB serverless)
- **UI Refresh**: < 200ms

## Scalability

- Backend can handle 1000+ requests/second
- Database can store millions of transactions
- App works offline (with SharedPreferences)
- Pagination prevents large data loads
