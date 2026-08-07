from fastapi import APIRouter, HTTPException
from app.models.schemas import SubscriptionCreate, SubscriptionUpdate
from app.db.firestore_service import store

router = APIRouter()

@router.get("/")
def list_subscriptions(user_id: str = "default_user"):
    return store.get_collection(user_id, "subscriptions")

@router.post("/", status_code=201)
def create_subscription(payload: SubscriptionCreate, user_id: str = "default_user"):
    data = payload.dict()
    return store.add_doc(user_id, "subscriptions", data)

@router.patch("/{sub_id}/toggle")
def toggle_subscription(sub_id: str, user_id: str = "default_user"):
    sub = store.get_doc(user_id, "subscriptions", sub_id)
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")
    new_active = not sub.get("active", True)
    return store.update_doc(user_id, "subscriptions", sub_id, {"active": new_active})

@router.put("/{sub_id}")
def update_subscription(sub_id: str, payload: SubscriptionUpdate, user_id: str = "default_user"):
    existing = store.get_doc(user_id, "subscriptions", sub_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Subscription not found")
    updates = {k: v for k, v in payload.dict().items() if v is not None}
    if not updates:
        return existing
    doc = store.update_doc(user_id, "subscriptions", sub_id, updates)
    return doc

@router.delete("/{sub_id}", status_code=204)
def delete_subscription(sub_id: str, user_id: str = "default_user"):
    success = store.delete_doc(user_id, "subscriptions", sub_id)
    if not success:
        raise HTTPException(status_code=404, detail="Subscription not found")

