from fastapi import APIRouter
from app.db.firestore_service import store
from datetime import datetime

router = APIRouter()

@router.get("/summary")
def get_summary(user_id: str = "default_user"):
    current_month = datetime.utcnow().strftime("%Y-%m")

    # Accounts
    accounts = store.get_collection(user_id, "accounts")
    total_balance = sum(a.get("balance", 0.0) for a in accounts)

    # Investments
    investments = store.get_collection(user_id, "investments")
    total_invested = sum(i.get("investedAmount", 0.0) for i in investments)
    total_current = sum(i.get("currentValue", 0.0) for i in investments)

    # Loans
    loans = store.get_collection(user_id, "loans")
    total_debt = sum(l.get("outstanding", 0.0) for l in loans)

    # Net Worth
    net_worth = total_balance + total_current - total_debt

    # Transactions
    txns = store.get_collection(user_id, "transactions")

    month_income = 0.0
    month_expense = 0.0
    category_totals = {}
    monthly_totals = {}

    for t in txns:
        t_date = t.get("date", "")
        t_month = t_date[:7] if len(t_date) >= 7 else ""
        t_type = t.get("type", "")
        amt = t.get("amount", 0.0)
        cat = t.get("category", "Other")

        if t_month == current_month:
            if t_type == "credit":
                month_income += amt
            elif t_type == "debit":
                month_expense += amt
                category_totals[cat] = category_totals.get(cat, 0.0) + amt

        if t_type == "debit" and t_month:
            monthly_totals[t_month] = monthly_totals.get(t_month, 0.0) + amt

    # Format spending by category
    spending_by_category = [
        {"category": k, "total": round(v, 2)}
        for k, v in sorted(category_totals.items(), key=lambda x: x[1], reverse=True)
    ]

    # Format monthly expenses (last 6 months)
    sorted_months = sorted(monthly_totals.keys(), reverse=True)[:6]
    monthly_expenses = [
        {"month": m, "expense": round(monthly_totals[m], 2)}
        for m in reversed(sorted_months)
    ]

    return {
        "net_worth": round(net_worth, 2),
        "total_balance": round(total_balance, 2),
        "total_invested": round(total_invested, 2),
        "total_current_value": round(total_current, 2),
        "investment_gain": round(total_current - total_invested, 2),
        "total_debt": round(total_debt, 2),
        "month_income": round(month_income, 2),
        "month_expense": round(month_expense, 2),
        "month_savings": round(month_income - month_expense, 2),
        "spending_by_category": spending_by_category,
        "monthly_expenses": monthly_expenses,
        "accounts": accounts,
    }
