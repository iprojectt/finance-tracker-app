# Personal Finance App (Firestore Edition)

A full-stack personal finance dashboard — **FastAPI backend + Flutter frontend** — powered by **Firestore** NoSQL schema. Runs as a native desktop app on your laptop and a native mobile app on your phone.

---

## Project Structure

```
FINANCIAL_DASBOARD_APP/
├── backend/                         # FastAPI + Firestore Backend
│   ├── app/
│   │   ├── main.py                  # API entry point & route registration
│   │   ├── api/                     # Modular Route Handlers
│   │   │   ├── accounts.py          # Savings, Current, UPI, Cash
│   │   │   ├── transactions.py      # Manual + CSV import + Auto-categorization
│   │   │   ├── loans.py             # Loans + emiPayments subcollection
│   │   │   ├── investments.py      # MF, Stocks, FD, PPF, Gold, Crypto (SIP/Lumpsum)
│   │   │   ├── subscriptions.py    # Recurring Netflix, Spotify, etc.
│   │   │   ├── goals.py            # Goa Trip, Savings Goals
│   │   │   ├── categories.py       # Default + User Custom Categories & Subcategories
│   │   │   └── dashboard.py        # Net Worth, Cash, Debt, Income/Expense breakdown
│   │   ├── models/schemas.py        # Pydantic models matching Firestore schema
│   │   ├── services/csv_parser.py   # Bank CSV Parsers (SBI, HDFC, Generic)
│   │   └── db/firestore_service.py  # Firestore SDK wrapper + mock store
│   ├── requirements.txt
│   ├── run.ps1                      # Windows PowerShell runner
│   └── run.sh                       # Linux/Mac bash runner
│
└── flutter_app/                     # Flutter Desktop + Mobile
    ├── lib/
    │   ├── main.dart                # Adaptive Shell (NavigationRail / BottomNav)
    │   ├── theme/app_theme.dart     # Modern dark financial UI theme
    │   ├── services/api_service.dart # HTTP REST client for all Firestore endpoints
    │   └── screens/
    │       ├── dashboard_screen.dart
    │       ├── transactions_screen.dart
    │       ├── accounts_screen.dart
    │       ├── loans_screen.dart
    │       ├── investments_screen.dart
    │       ├── subscriptions_screen.dart
    │       ├── goals_screen.dart
    │       ├── categories_screen.dart
    │       └── settings_screen.dart
    └── pubspec.yaml
```

---

## Firestore Schema & Subcollections (`users/{userId}`)

- `accounts/{accountId}`: name, type (`savings`|`current`|`upi`|`cash`), subtype (`PhonePe`|`Paytm`), balance, currency
- `transactions/{txnId}`: accountId, amount, type (`credit`|`debit`), category, subcategory, description, date, source
- `loans/{loanId}`: name, type (`personal`|`credit_card`|`friend_family`|`education`), lender, principal, outstanding, interestRate, emi, tenureMonths, startDate
  - `emiPayments/{paymentId}`: date, amount, principalPaid, interestPaid, balanceAfter
- `investments/{investmentId}`: name, type (`mutual_fund`|`stocks`|`fd`|`ppf`|`gold`|`crypto`), subtype (`SIP`|`Lumpsum`|scrip name), platform, investedAmount, currentValue, units, startDate
- `subscriptions/{subId}`: name, amount, cycle (`monthly`|`yearly`), nextDueDate, category, active
- `goals/{goalId}`: name, targetAmount, savedAmount, deadline, category
- `categories/{catId}`: name, subcategories, type, icon

### Preloaded Default Categories
- **Food** → Groceries, Restaurants, Coffee, Drinks
- **Transport** → Uber/Ola, Petrol, Metro, Auto
- **Rent** → Home/Flat, Scooty
- **Medicines** → Homeopathy, Allopathy
- **Subscriptions** → Netflix, Spotify, Amazon Prime, JioHotstar, Airlearn, Sheryians
- **Goals** → Trip, Gifts, Clothes

---

## How to Run

### 1. Backend

**Windows (PowerShell)**:
```powershell
cd backend
powershell ./run.ps1
```

To allow your phone on the same WiFi to connect:
```powershell
powershell ./run.ps1 -HostNetwork
```

**Linux / Mac**:
```bash
cd backend
chmod +x run.sh
./run.sh --host
```

Backend runs at `http://localhost:8000`. API Documentation is at `http://localhost:8000/docs`.

### 2. Flutter App

```bash
cd flutter_app
flutter pub get

# Desktop App (Windows/Mac/Linux):
flutter run -d windows

# Mobile App (Android):
flutter run -d android
```
