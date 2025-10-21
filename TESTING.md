# Testing Guide - Auto Spend Tracker

## 🎯 What to Test

### ✅ Backend Status
- Backend running at: http://localhost:8000
- Database: Connected to NeonDB
- Test data: 2 transactions already in database

---

## 📱 Frontend Testing Options

### Option 1: Manual Entry (Easiest - Start Here!)

1. **Open the app** - Wait for Flutter to finish building
2. **Tap "Add Manual" button** (floating action button at bottom-right)
3. **Pre-filled SMS appears** - You can use it or modify
4. **Enter user input**: `mom, apples` (or try: `dad, groceries`, `self, shopping`)
5. **Tap Submit**
6. **Check for**:
   - ✅ Success notification appears
   - ✅ Transaction appears in the list
   - ✅ Card shows: person, reason, amount, date
   - ✅ Tap card to expand and see full details

**Sample SMS texts to try:**
```
Sent Rs.150.00 from Kotak Bank AC X0396 to friend.upi@paytm on 07-07-25
Received Rs.1000.00 to Kotak Bank AC X0396 from salary.upi@hdfc on 08-07-25
Debited Rs.45.50 from Kotak Bank AC X0396 at POS on 09-07-25
```

**User input formats:**
```
mom, groceries
dad, fuel
self, lunch
friend, repayment
```

---

### Option 2: Test with Emulator SMS

1. **Open Extended Controls** - Click ⋮ on emulator toolbar
2. **Go to Phone > SMS**
3. **Enter sender**: `AX-KOTAK-S`
4. **Enter message**:
   ```
   Sent Rs.236.00 from Kotak Bank AC X0396 to vyapar.172400950852@hdfcbank on 05-07-25.UPI Ref 555256646612.
   ```
5. **Click "Send Message"**
6. **Check for**:
   - 🔔 Notification appears: "💸 Money Sent - ₹236.00"
   - 📝 Notification has text input box (inline reply)
7. **In notification, type**: `mom, apples`
8. **Tap send/submit in notification**
9. **Check for**:
   - ✅ Success notification: "Transaction Saved"
   - 📊 Open app - new transaction appears in list

---

### Option 3: Check Existing Transactions

1. **App should load 2 existing transactions** from database:
   - Transaction 1: mom, apples, ₹236.00 (sent)
   - Transaction 2: dad, monthly allowance, ₹500.00 (received)
2. **Tap Refresh button** (top-right) to reload from backend
3. **Expand cards** to see full details:
   - Date, Time, Amount
   - Transaction Type (Sent/Received)
   - UPI ID or Account
   - Person (applicable_to)
   - Reason
   - Full SMS text

---

## 🔍 What to Look For

### ✅ App Launch
- [x] App opens without errors
- [x] Permissions requested (SMS, Notifications)
- [x] Loads existing transactions from backend

### ✅ UI Elements
- [x] Transaction cards with color coding:
  - 🔴 Red for "sent" transactions
  - 🟢 Green for "received" transactions
- [x] Expandable cards show full details
- [x] Floating action button "Add Manual"
- [x] Refresh button in app bar

### ✅ Manual Entry
- [x] Dialog opens with pre-filled SMS
- [x] Can enter custom SMS and user input
- [x] Submits to backend
- [x] Shows success notification
- [x] Transaction appears in list immediately

### ✅ SMS Detection (if testing with emulator)
- [x] Detects SMS from "kotak" senders
- [x] Shows notification with amount
- [x] Notification has inline text input
- [x] User can type in notification
- [x] Sends to backend when submitted

### ✅ Backend Integration
- [x] POST request creates transaction
- [x] GET request fetches all transactions
- [x] Proper error handling
- [x] Success/error notifications shown

---

## 🐛 Troubleshooting

### App not loading transactions?
- Check backend is running: http://localhost:8000/health
- Check API URL in `lib/services/api_service.dart`
- For emulator: Must use `http://10.0.2.2:8000` (not localhost)
- Check Android emulator has internet access

### SMS not detected?
- Grant SMS permissions in app settings
- Check sender contains "kotak" (case-insensitive)
- Use emulator SMS tool for testing

### Notifications not showing?
- Grant notification permissions
- For Android 13+: POST_NOTIFICATIONS permission required
- Check notification settings for the app

### Inline reply not working?
- Feature requires Android 7.0+ (API 24+)
- Some custom Android skins may restrict it
- Try manual entry instead

---

## 📊 Expected Flow

```
1. SMS arrives (or manual entry)
   ↓
2. App detects & parses (amount, type)
   ↓
3. Shows notification with input
   ↓
4. User types: "person, reason"
   ↓
5. Sends to backend API
   ↓
6. Backend parses & saves to database
   ↓
7. Returns success
   ↓
8. App shows success notification
   ↓
9. Transaction list refreshes
   ↓
10. Transaction visible in app
```

---

## ✨ Test Checklist

- [ ] App launches successfully
- [ ] Grants SMS and notification permissions
- [ ] Shows existing 2 transactions from database
- [ ] Manual entry works (Add Manual button)
- [ ] Transaction appears in list after creation
- [ ] Cards expand to show full details
- [ ] Refresh button reloads data
- [ ] Color coding correct (red=sent, green=received)
- [ ] Success notifications appear
- [ ] SMS detection works (if testing with emulator)
- [ ] Inline reply notification works

---

## 🎉 Success Criteria

Your app is working correctly if:
1. ✅ Shows 2 existing transactions on first load
2. ✅ Manual entry creates new transaction
3. ✅ New transaction appears in the list
4. ✅ Tapping card shows all details
5. ✅ Backend logs show API requests
6. ✅ Database contains the new transaction

---

**Good luck with testing! 🚀**
