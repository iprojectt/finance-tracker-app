from fastapi import APIRouter, HTTPException
from app.models.schemas import CategoryCreate
from app.db.firestore_service import store

router = APIRouter()

@router.get("/")
def list_categories(user_id: str = "default_user"):
    categories = store.get_collection(user_id, "categories")
    if not categories:
        store.preload_default_categories(user_id)
        categories = store.get_collection(user_id, "categories")
    return categories

@router.post("/", status_code=201)
def create_category(payload: CategoryCreate, user_id: str = "default_user"):
    data = payload.dict()
    return store.add_doc(user_id, "categories", data)

@router.delete("/{cat_id}", status_code=204)
def delete_category(cat_id: str, user_id: str = "default_user"):
    success = store.delete_doc(user_id, "categories", cat_id)
    if not success:
        raise HTTPException(status_code=404, detail="Category not found")
