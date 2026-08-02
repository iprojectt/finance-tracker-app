from fastapi import APIRouter, HTTPException, Header
from app.models.schemas import AccountCreate, AccountUpdate
from app.db.firestore_service import store

router = APIRouter()

def get_user_id(x_user_id: str = Header(default="default_user")) -> str:
    return x_user_id

@router.get("/")
def list_accounts(user_id: str = "default_user"):
    return store.get_collection(user_id, "accounts")

@router.post("/", status_code=201)
def create_account(payload: AccountCreate, user_id: str = "default_user"):
    data = payload.dict()
    return store.add_doc(user_id, "accounts", data)

@router.get("/{account_id}")
def get_account(account_id: str, user_id: str = "default_user"):
    doc = store.get_doc(user_id, "accounts", account_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Account not found")
    return doc

@router.patch("/{account_id}")
def update_account(account_id: str, payload: AccountUpdate, user_id: str = "default_user"):
    updates = {k: v for k, v in payload.dict().items() if v is not None}
    doc = store.update_doc(user_id, "accounts", account_id, updates)
    if not doc:
        raise HTTPException(status_code=404, detail="Account not found")
    return doc

@router.delete("/{account_id}", status_code=204)
def delete_account(account_id: str, user_id: str = "default_user"):
    success = store.delete_doc(user_id, "accounts", account_id)
    if not success:
        raise HTTPException(status_code=404, detail="Account not found")
