from pydantic import BaseModel, Field
from typing import Optional, List

# ── Accounts ──────────────────────────────────────────────
class AccountCreate(BaseModel):
    name: str
    type: str = "savings"  # savings | current | upi | cash
    subtype: Optional[str] = None  # PhonePe | Paytm | SBI | etc
    balance: float = 0.0
    currency: str = "INR"

class AccountUpdate(BaseModel):
    name: Optional[str] = None
    subtype: Optional[str] = None
    balance: Optional[float] = None

class Account(AccountCreate):
    id: str
    createdAt: str

# ── Transactions ───────────────────────────────────────────
class TransactionCreate(BaseModel):
    accountId: str
    amount: float
    type: str  # credit | debit
    category: Optional[str] = None
    subcategory: Optional[str] = None
    description: Optional[str] = None
    date: str  # YYYY-MM-DD
    source: str = "manual"  # manual | csv_import

class Transaction(TransactionCreate):
    id: str
    createdAt: str

# ── Loans & EMI Payments ───────────────────────────────────
class EMIPaymentCreate(BaseModel):
    date: str
    amount: float
    principalPaid: float
    interestPaid: float
    balanceAfter: float

class EMIPayment(EMIPaymentCreate):
    id: str

class LoanCreate(BaseModel):
    name: str
    type: str = "personal"  # personal | credit_card | friend_family | education
    lender: Optional[str] = None
    principal: float
    outstanding: float
    interestRate: float  # annual %
    emi: float
    tenureMonths: int
    startDate: str

class Loan(LoanCreate):
    id: str
    createdAt: str

# ── Investments ────────────────────────────────────────────
class InvestmentCreate(BaseModel):
    name: str
    type: str  # mutual_fund | stocks | fd | ppf | gold | crypto
    subtype: Optional[str] = None  # SIP | Lumpsum | scrip name
    platform: Optional[str] = None
    investedAmount: float
    currentValue: float
    units: Optional[float] = None
    startDate: Optional[str] = None

class Investment(InvestmentCreate):
    id: str
    createdAt: str

# ── Subscriptions ──────────────────────────────────────────
class SubscriptionCreate(BaseModel):
    name: str
    amount: float
    cycle: str = "monthly"  # monthly | yearly
    nextDueDate: str  # YYYY-MM-DD
    category: str = "Entertainment"
    active: bool = True

class Subscription(SubscriptionCreate):
    id: str
    createdAt: str

# ── Goals ──────────────────────────────────────────────────
class GoalCreate(BaseModel):
    name: str
    targetAmount: float
    savedAmount: float = 0.0
    deadline: str  # YYYY-MM-DD
    category: str = "Travel"

class Goal(GoalCreate):
    id: str
    createdAt: str

# ── Categories ─────────────────────────────────────────────
class CategoryCreate(BaseModel):
    name: str
    subcategories: List[str] = []
    type: str = "transaction"
    icon: Optional[str] = "category"

class Category(CategoryCreate):
    id: str
    createdAt: str
