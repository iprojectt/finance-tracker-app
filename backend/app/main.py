from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import accounts, transactions, loans, investments, subscriptions, goals, categories, dashboard
from app.db.firestore_service import store

app = FastAPI(title="Personal Finance API (Firestore Backend)", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup():
    # Preload default categories for default_user on startup
    store.preload_default_categories("default_user")

app.include_router(accounts.router, prefix="/api/accounts", tags=["Accounts"])
app.include_router(transactions.router, prefix="/api/transactions", tags=["Transactions"])
app.include_router(loans.router, prefix="/api/loans", tags=["Loans"])
app.include_router(investments.router, prefix="/api/investments", tags=["Investments"])
app.include_router(subscriptions.router, prefix="/api/subscriptions", tags=["Subscriptions"])
app.include_router(goals.router, prefix="/api/goals", tags=["Goals"])
app.include_router(categories.router, prefix="/api/categories", tags=["Categories"])
app.include_router(dashboard.router, prefix="/api/dashboard", tags=["Dashboard"])

@app.get("/")
def root():
    return {"message": "Personal Finance API (Firestore Enabled) is running"}
