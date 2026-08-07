from fastapi import APIRouter, HTTPException, UploadFile, File, Query
from app.models.schemas import TransactionCreate, TransactionUpdate
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

@router.put("/{txn_id}")
def update_transaction(txn_id: str, payload: TransactionUpdate, user_id: str = "default_user"):
    old_txn = store.get_doc(user_id, "transactions", txn_id)
    if not old_txn:
        raise HTTPException(status_code=404, detail="Transaction not found")

    updates = {k: v for k, v in payload.dict().items() if v is not None}
    if not updates:
        return old_txn

    # Step 1: Reverse old transaction's effect on its account balance
    old_acc_id = old_txn.get("accountId")
    if old_acc_id:
        old_acc = store.get_doc(user_id, "accounts", old_acc_id)
        if old_acc:
            old_delta = -old_txn.get("amount", 0.0) if old_txn.get("type") == "credit" else old_txn.get("amount", 0.0)
            store.update_doc(user_id, "accounts", old_acc_id, {
                "balance": round(old_acc.get("balance", 0.0) + old_delta, 2)
            })

    # Step 2: Apply the update
    updated_txn = store.update_doc(user_id, "transactions", txn_id, updates)

    # Step 3: Apply new transaction's effect on its (possibly new) account balance
    new_acc_id = updated_txn.get("accountId")
    if new_acc_id:
        new_acc = store.get_doc(user_id, "accounts", new_acc_id)
        if new_acc:
            new_delta = updated_txn.get("amount", 0.0) if updated_txn.get("type") == "credit" else -updated_txn.get("amount", 0.0)
            store.update_doc(user_id, "accounts", new_acc_id, {
                "balance": round(new_acc.get("balance", 0.0) + new_delta, 2)
            })

    return updated_txn

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

