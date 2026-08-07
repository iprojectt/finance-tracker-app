from fastapi import APIRouter, HTTPException
from app.models.schemas import GoalCreate, GoalUpdate
from app.db.firestore_service import store

router = APIRouter()

@router.get("/")
def list_goals(user_id: str = "default_user"):
    goals = store.get_collection(user_id, "goals")
    res = []
    for g in goals:
        target = g.get("targetAmount", 1.0)
        saved = g.get("savedAmount", 0.0)
        pct = (saved / target * 100) if target > 0 else 0.0
        g_copy = dict(g)
        g_copy["progress_pct"] = round(min(pct, 100.0), 1)
        res.append(g_copy)
    return res

@router.post("/", status_code=201)
def create_goal(payload: GoalCreate, user_id: str = "default_user"):
    data = payload.dict()
    return store.add_doc(user_id, "goals", data)

@router.patch("/{goal_id}/add-savings")
def add_savings(goal_id: str, amount: float, user_id: str = "default_user"):
    goal = store.get_doc(user_id, "goals", goal_id)
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    new_saved = goal.get("savedAmount", 0.0) + amount
    return store.update_doc(user_id, "goals", goal_id, {"savedAmount": round(new_saved, 2)})

@router.put("/{goal_id}")
def update_goal(goal_id: str, payload: GoalUpdate, user_id: str = "default_user"):
    existing = store.get_doc(user_id, "goals", goal_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Goal not found")
    updates = {k: v for k, v in payload.dict().items() if v is not None}
    if not updates:
        return existing
    doc = store.update_doc(user_id, "goals", goal_id, updates)
    return doc

@router.delete("/{goal_id}", status_code=204)
def delete_goal(goal_id: str, user_id: str = "default_user"):
    success = store.delete_doc(user_id, "goals", goal_id)
    if not success:
        raise HTTPException(status_code=404, detail="Goal not found")

