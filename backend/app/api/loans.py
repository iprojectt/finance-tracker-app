from fastapi import APIRouter, HTTPException
from app.models.schemas import LoanCreate
from app.db.firestore_service import store
from datetime import datetime

router = APIRouter()

def amortization_schedule(principal: float, annual_rate: float, tenure_months: int, emi: float):
    monthly_rate = annual_rate / 100 / 12 if annual_rate else 0
    schedule = []
    balance = principal
    for month in range(1, tenure_months + 1):
        interest = balance * monthly_rate
        principal_paid = emi - interest
        balance -= principal_paid
        schedule.append({
            "month": month,
            "emi": round(emi, 2),
            "principal_paid": round(principal_paid, 2),
            "interest_paid": round(interest, 2),
            "balance": round(max(balance, 0), 2),
        })
        if balance <= 0:
            break
    return schedule

@router.get("/")
def list_loans(user_id: str = "default_user"):
    loans = store.get_collection(user_id, "loans")
    result = []
    for loan in loans:
        l = dict(loan)
        emi = l.get("emi", 0.0)
        principal = l.get("principal", 0.0)
        outstanding = l.get("outstanding", 0.0)
        tenure = l.get("tenureMonths", 0)

        months_paid = round((principal - outstanding) / emi) if emi else 0
        l["months_remaining"] = max(tenure - months_paid, 0)
        l["total_interest"] = round(emi * tenure - principal, 2) if emi and tenure else 0.0
        result.append(l)
    return result

@router.post("/", status_code=201)
def create_loan(payload: LoanCreate, user_id: str = "default_user"):
    data = payload.dict()
    return store.add_doc(user_id, "loans", data)

@router.get("/{loan_id}/schedule")
def get_amortization(loan_id: str, user_id: str = "default_user"):
    loan = store.get_doc(user_id, "loans", loan_id)
    if not loan:
        raise HTTPException(status_code=404, detail="Loan not found")

    schedule = amortization_schedule(
        loan.get("outstanding", 0.0),
        loan.get("interestRate", 0.0),
        loan.get("tenureMonths", 0),
        loan.get("emi", 0.0)
    )
    return {"loan": loan, "schedule": schedule}

@router.get("/{loan_id}/payments")
def get_emi_payments(loan_id: str, user_id: str = "default_user"):
    return store.get_subcollection_docs(user_id, "loans", loan_id, "emiPayments")

@router.patch("/{loan_id}/pay-emi")
def record_emi_payment(loan_id: str, user_id: str = "default_user"):
    loan = store.get_doc(user_id, "loans", loan_id)
    if not loan:
        raise HTTPException(status_code=404, detail="Loan not found")

    outstanding = loan.get("outstanding", 0.0)
    rate = loan.get("interestRate", 0.0)
    emi = loan.get("emi", 0.0)

    monthly_rate = rate / 100 / 12 if rate else 0
    interest = outstanding * monthly_rate
    principal_paid = emi - interest
    new_outstanding = max(outstanding - principal_paid, 0.0)

    store.update_doc(user_id, "loans", loan_id, {"outstanding": round(new_outstanding, 2)})

    # Record in emiPayments subcollection
    payment_doc = {
        "date": datetime.utcnow().strftime("%Y-%m-%d"),
        "amount": round(emi, 2),
        "principalPaid": round(principal_paid, 2),
        "interestPaid": round(interest, 2),
        "balanceAfter": round(new_outstanding, 2)
    }
    store.add_subcollection_doc(user_id, "loans", loan_id, "emiPayments", payment_doc)

    return {
        "outstanding": round(new_outstanding, 2),
        "interest_paid": round(interest, 2),
        "principal_paid": round(principal_paid, 2)
    }

@router.delete("/{loan_id}", status_code=204)
def delete_loan(loan_id: str, user_id: str = "default_user"):
    success = store.delete_doc(user_id, "loans", loan_id)
    if not success:
        raise HTTPException(status_code=404, detail="Loan not found")
