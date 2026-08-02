from fastapi import APIRouter, HTTPException
from app.models.schemas import SubscriptionCreate
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

@router.delete("/{sub_id}", status_code=204)
def delete_subscription(sub_id: str, user_id: str = "default_user"):
    success = store.delete_doc(user_id, "subscriptions", sub_id)
    if not success:
        raise HTTPException(status_code=404, detail="Subscription not found")
