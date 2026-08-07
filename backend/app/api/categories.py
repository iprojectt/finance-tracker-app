from fastapi import APIRouter, HTTPException
from app.models.schemas import CategoryCreate
from app.db.firestore_service import store

router = APIRouter()

@router.get("/")
def list_categories(user_id: str = "default_user", month: str = None):
    from datetime import datetime
    categories = store.get_collection(user_id, "categories")
    if not categories:
        store.preload_default_categories(user_id)
        categories = store.get_collection(user_id, "categories")
        
    txns = store.get_collection(user_id, "transactions")
    target_month = month if month else datetime.utcnow().strftime("%Y-%m")
    
    cat_totals = {}
    subcat_totals = {}
    
    for t in txns:
        if t.get("type") == "debit" and t.get("date", "").startswith(target_month):
            c = t.get("category", "Other")
            sc = t.get("subcategory", "")
            amt = t.get("amount", 0.0)
            
            cat_totals[c] = cat_totals.get(c, 0.0) + amt
            if sc:
                if c not in subcat_totals:
                    subcat_totals[c] = {}
                subcat_totals[c][sc] = subcat_totals[c].get(sc, 0.0) + amt

    for cat in categories:
        c_name = cat.get("name", "")
        cat["total_spent"] = round(cat_totals.get(c_name, 0.0), 2)
        cat["subcategory_totals"] = {}
        for sc in cat.get("subcategories", []):
            if c_name in subcat_totals:
                cat["subcategory_totals"][sc] = round(subcat_totals[c_name].get(sc, 0.0), 2)
            else:
                cat["subcategory_totals"][sc] = 0.0

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
