from fastapi import APIRouter, HTTPException
from app.models.schemas import InvestmentCreate
from app.db.firestore_service import store

router = APIRouter()

@router.get("/")
def list_investments(user_id: str = "default_user"):
    investments = store.get_collection(user_id, "investments")
    result = []
    for inv in investments:
        i = dict(inv)
        invested = i.get("investedAmount", 0.0)
        current = i.get("currentValue", 0.0)
        gain = current - invested
        ret_pct = (gain / invested * 100) if invested > 0 else 0.0
        i["gain_loss"] = round(gain, 2)
        i["return_pct"] = round(ret_pct, 2)
        result.append(i)
    return result

@router.post("/", status_code=201)
def create_investment(payload: InvestmentCreate, user_id: str = "default_user"):
    data = payload.dict()
    return store.add_doc(user_id, "investments", data)

@router.patch("/{investment_id}")
def update_current_value(investment_id: str, current_value: float, user_id: str = "default_user"):
    doc = store.update_doc(user_id, "investments", investment_id, {"currentValue": current_value})
    if not doc:
        raise HTTPException(status_code=404, detail="Investment not found")
    return doc

@router.delete("/{investment_id}", status_code=204)
def delete_investment(investment_id: str, user_id: str = "default_user"):
    success = store.delete_doc(user_id, "investments", investment_id)
    if not success:
        raise HTTPException(status_code=404, detail="Investment not found")
