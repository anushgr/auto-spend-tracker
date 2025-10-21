# Auto Spend Tracker - Backend

FastAPI backend for the Auto Spend Tracker application. Receives transaction data from Flutter frontend, parses bank SMS messages, and stores data in NeonDB (PostgreSQL).

## Features

- REST API for transaction management
- Automatic SMS parsing for Kotak Bank messages
- PostgreSQL database with async support (NeonDB compatible)
- User input parsing (person, reason extraction)
- Pagination support for transaction listing

## Setup

### Prerequisites
- Python 3.8+
- PostgreSQL database (NeonDB account recommended)

### Installation

1. Create virtual environment:
```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
```

2. Install dependencies:
```powershell
pip install -r requirements.txt
```

3. Configure environment:
```powershell
cp .env.example .env
```

Edit `.env` and set your NeonDB connection string:
```
DATABASE_URL=postgresql+asyncpg://username:password@ep-xxx.region.aws.neon.tech/neondb?sslmode=require
```

### Run

```powershell
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

API will be available at:
- Main: http://localhost:8000
- Docs: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## API Endpoints

### POST /api/transactions
Create a new transaction from SMS + user input.

**Request body:**
```json
{
  "sms_text": "Sent Rs.236.00 from Kotak Bank AC X0396 to vyapar.172400950852@hdfcbank on 05-07-25.UPI Ref 555256646612.",
  "user_input": "mom, apples"
}
```

**Response:**
```json
{
  "id": 1,
  "date": "05-07-25",
  "time": null,
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

### GET /api/transactions
Fetch all transactions with pagination.

**Query params:**
- `page` (default: 1)
- `page_size` (default: 50, max: 100)

### GET /api/transactions/{id}
Get a specific transaction by ID.

## Database Schema

**transactions** table:
- `id`: Primary key
- `date`: Transaction date from SMS (DD-MM-YY)
- `time`: Time if available
- `amount`: Transaction amount
- `transaction_type`: 'sent' or 'received'
- `sender_receiver_info`: UPI ID or account number
- `applicable_to`: Person (from user input)
- `reason`: Reason (from user input)
- `full_text`: Complete user input
- `sms_text`: Original SMS message
- `created_at`: Timestamp

## SMS Parsing

The parser extracts:
- **Amount**: Rs.XXX.XX pattern
- **Type**: Sent/Received keywords
- **UPI/Account**: UPI ID format or AC XXXXX
- **Date**: DD-MM-YY format

User input is split by comma: `person, reason`

## Development

Run tests:
```powershell
pytest
```

Check code:
```powershell
black .
flake8 .
```
