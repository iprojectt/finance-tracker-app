from fastapi import APIRouter, HTTPException, UploadFile, File, Query
from app.models.schemas import TransactionCreate
from app.db.firestore_service import store
from app.services.csv_parser import parse_bank_csv
from typing import Optional

router = APIRouter()

def auto_categorize(description: str, user_id: str = "default_user") -> tuple:
    desc = (description or "").lower()
    categories = store.get_collection(user_id, "categories")
    if not categories:
        store.preload_default_categories(user_id)
        categories = store.get_collection(user_id, "categories")

    for cat in categories:
        name = cat.get("name", "")
        subs = cat.get("subcategories", [])
        for sub in subs:
            if sub.lower() in desc:
                return name, sub
        if name.lower() in desc:
            return name, (subs[0] if subs else None)

    # Keyword fallback
    rules = {
        "Food": (["swiggy", "zomato", "restaurant", "cafe", "food", "hotel", "biryani"], "Restaurants"),
        "Transport": (["uber", "ola", "rapido", "petrol", "fuel", "irctc", "flight", "bus", "auto"], "Uber/Ola"),
        "Rent": (["rent", "pg", "hostel"], "Home/Flat"),
        "Medicines": (["pharmacy", "hospital", "clinic", "doctor", "medical", "apollo"], "Allopathy"),
        "Subscriptions": (["netflix", "spotify", "prime", "hotstar", "jio", "airlearn"], "Netflix"),
        "Goals": (["trip", "gift", "clothes"], "Trip"),
    }
    for cat_name, (keywords, default_sub) in rules.items():
        if any(k in desc for k in keywords):
            return cat_name, default_sub

    return "Food", "Other"

@router.get("/")
def list_transactions(
    account_id: Optional[str] = None,
    category: Optional[str] = None,
    month: Optional[str] = None,  # YYYY-MM
    limit: int = Query(default=100, le=500),
    offset: int = 0,
    user_id: str = "default_user"
):
    txns = store.get_collection(user_id, "transactions")
    accounts = {a["id"]: a.get("name", "") for a in store.get_collection(user_id, "accounts")}

    filtered = []
    for t in txns:
        if account_id and t.get("accountId") != account_id:
            continue
        if category and t.get("category") != category:
            continue
        if month and not t.get("date", "").startswith(month):
            continue
        t_copy = dict(t)
        t_copy["account_name"] = accounts.get(t.get("accountId", ""), "Unknown Account")
        filtered.append(t_copy)

    filtered.sort(key=lambda x: x.get("date", ""), reverse=True)
    return filtered[offset:offset + limit]

@router.post("/", status_code=201)
def create_transaction(payload: TransactionCreate, user_id: str = "default_user"):
    cat, subcat = payload.category, payload.subcategory
    if not cat:
        cat, subcat = auto_categorize(payload.description or "", user_id)

    data = payload.dict()
    data["category"] = cat
    data["subcategory"] = subcat

    new_txn = store.add_doc(user_id, "transactions", data)

    # Update account balance
    acc = store.get_doc(user_id, "accounts", payload.accountId)
    if acc:
        delta = payload.amount if payload.type == "credit" else -payload.amount
        new_bal = acc.get("balance", 0.0) + delta
        store.update_doc(user_id, "accounts", payload.accountId, {"balance": round(new_bal, 2)})

    return new_txn

@router.post("/import-csv")
async def import_csv(account_id: str, file: UploadFile = File(...), user_id: str = "default_user"):
    content = await file.read()
    try:
        transactions = parse_bank_csv(content.decode("utf-8"), account_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"CSV parse error: {str(e)}")

    inserted = 0
    total_delta = 0.0
    for t in transactions:
        cat, subcat = auto_categorize(t.get("description", ""), user_id)
        t["category"] = cat
        t["subcategory"] = subcat
        t["source"] = "csv_import"
        store.add_doc(user_id, "transactions", t)
        inserted += 1
        total_delta += (t["amount"] if t["type"] == "credit" else -t["amount"])

    acc = store.get_doc(user_id, "accounts", account_id)
    if acc:
        new_bal = acc.get("balance", 0.0) + total_delta
        store.update_doc(user_id, "accounts", account_id, {"balance": round(new_bal, 2)})

    return {"imported": inserted}

@router.delete("/{txn_id}", status_code=204)
def delete_transaction(txn_id: str, user_id: str = "default_user"):
    txn = store.get_doc(user_id, "transactions", txn_id)
    if not txn:
        raise HTTPException(status_code=404, detail="Transaction not found")

    # Reverse account balance update
    acc_id = txn.get("accountId")
    if acc_id:
        acc = store.get_doc(user_id, "accounts", acc_id)
        if acc:
            delta = -txn.get("amount", 0.0) if txn.get("type") == "credit" else txn.get("amount", 0.0)
            store.update_doc(user_id, "accounts", acc_id, {"balance": round(acc.get("balance", 0.0) + delta, 2)})

    store.delete_doc(user_id, "transactions", txn_id)
