import os
import uuid
from datetime import datetime
from typing import Dict, List, Any, Optional

# Attempt to import firebase_admin
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False

DEFAULT_CATEGORIES = [
    {
        "name": "Food",
        "subcategories": ["Groceries", "Restaurants", "Coffee", "Drinks"],
        "type": "transaction",
        "icon": "restaurant"
    },
    {
        "name": "Transport",
        "subcategories": ["Uber/Ola", "Petrol", "Metro", "Auto"],
        "type": "transaction",
        "icon": "directions_car"
    },
    {
        "name": "Rent",
        "subcategories": ["Home/Flat", "Scooty"],
        "type": "transaction",
        "icon": "home"
    },
    {
        "name": "Medicines",
        "subcategories": ["Homeopathy", "Allopathy"],
        "type": "transaction",
        "icon": "medical_services"
    },
    {
        "name": "Subscriptions",
        "subcategories": ["Netflix", "Spotify", "Amazon Prime", "JioHotstar", "Airlearn", "Sheryians"],
        "type": "subscription",
        "icon": "subscriptions"
    },
    {
        "name": "Goals",
        "subcategories": ["Trip", "Gifts", "Clothes"],
        "type": "goal",
        "icon": "flag"
    }
]

class FirestoreStore:
    def __init__(self):
        self.db = None
        self.use_mock = True
        self.memory_store: Dict[str, Dict[str, Dict[str, Dict[str, Any]]]] = {}
        self._init_firebase()

    def _init_firebase(self):
        if not FIREBASE_AVAILABLE:
            print("⚠️ firebase-admin package not installed. Operating in high-speed local mode.")
            return

        cred_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
        
        # --- RENDER CLOUD DEPLOYMENT FIX ---
        if not cred_path or not os.path.exists(cred_path):
            cred_json = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS_JSON")
            if cred_json:
                import tempfile
                # Firebase SDK requires a physical file. Write the JSON string to a temporary file.
                fd, temp_path = tempfile.mkstemp(suffix=".json")
                with os.fdopen(fd, 'w') as f:
                    f.write(cred_json)
                cred_path = temp_path
                os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = temp_path
        # -----------------------------------

        if cred_path and os.path.exists(cred_path):
            try:
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                self.db = firestore.client()
                self.use_mock = False
                print("🔥 Firestore initialized successfully with service account.")
            except Exception as e:
                print(f"⚠️ Could not initialize Firebase Admin SDK: {e}. Falling back to memory store.")
        else:
            print("ℹ️ GOOGLE_APPLICATION_CREDENTIALS not set or file not found. Using local in-memory store.")

    def get_collection(self, user_id: str, collection_name: str) -> List[Dict[str, Any]]:
        if not self.use_mock and self.db:
            docs = self.db.collection('users').document(user_id).collection(collection_name).stream()
            res = []
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                res.append(data)
            return res

        # In-memory store logic
        user_data = self.memory_store.setdefault(user_id, {})
        col_data = user_data.setdefault(collection_name, {})
        return list(col_data.values())

    def get_doc(self, user_id: str, collection_name: str, doc_id: str) -> Optional[Dict[str, Any]]:
        if not self.use_mock and self.db:
            doc = self.db.collection('users').document(user_id).collection(collection_name).document(doc_id).get()
            if doc.exists:
                data = doc.to_dict()
                data['id'] = doc.id
                return data
            return None

        user_data = self.memory_store.get(user_id, {})
        col_data = user_data.get(collection_name, {})
        return col_data.get(doc_id)

    def add_doc(self, user_id: str, collection_name: str, data: Dict[str, Any]) -> Dict[str, Any]:
        doc_id = str(uuid.uuid4())[:8]
        data_copy = dict(data)
        data_copy['id'] = doc_id
        if 'createdAt' not in data_copy or not data_copy['createdAt']:
            data_copy['createdAt'] = datetime.utcnow().isoformat()

        if not self.use_mock and self.db:
            doc_ref = self.db.collection('users').document(user_id).collection(collection_name).document(doc_id)
            doc_ref.set(data_copy)
            return data_copy

        user_data = self.memory_store.setdefault(user_id, {})
        col_data = user_data.setdefault(collection_name, {})
        col_data[doc_id] = data_copy
        return data_copy

    def update_doc(self, user_id: str, collection_name: str, doc_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        if not self.use_mock and self.db:
            doc_ref = self.db.collection('users').document(user_id).collection(collection_name).document(doc_id)
            doc_ref.update(updates)
            doc = doc_ref.get()
            if doc.exists:
                d = doc.to_dict()
                d['id'] = doc.id
                return d
            return None

        user_data = self.memory_store.setdefault(user_id, {})
        col_data = user_data.setdefault(collection_name, {})
        if doc_id in col_data:
            col_data[doc_id].update(updates)
            return col_data[doc_id]
        return None

    def delete_doc(self, user_id: str, collection_name: str, doc_id: str) -> bool:
        if not self.use_mock and self.db:
            self.db.collection('users').document(user_id).collection(collection_name).document(doc_id).delete()
            return True

        user_data = self.memory_store.get(user_id, {})
        col_data = user_data.get(collection_name, {})
        if doc_id in col_data:
            del col_data[doc_id]
            return True
        return False

    # Subcollection methods for loan EMI payments
    def add_subcollection_doc(self, user_id: str, parent_col: str, parent_id: str, sub_col: str, data: Dict[str, Any]) -> Dict[str, Any]:
        doc_id = str(uuid.uuid4())[:8]
        data_copy = dict(data)
        data_copy['id'] = doc_id

        if not self.use_mock and self.db:
            sub_ref = self.db.collection('users').document(user_id).collection(parent_col).document(parent_id).collection(sub_col).document(doc_id)
            sub_ref.set(data_copy)
            return data_copy

        path = f"{parent_col}/{parent_id}/{sub_col}"
        user_data = self.memory_store.setdefault(user_id, {})
        col_data = user_data.setdefault(path, {})
        col_data[doc_id] = data_copy
        return data_copy

    def get_subcollection_docs(self, user_id: str, parent_col: str, parent_id: str, sub_col: str) -> List[Dict[str, Any]]:
        if not self.use_mock and self.db:
            docs = self.db.collection('users').document(user_id).collection(parent_col).document(parent_id).collection(sub_col).stream()
            res = []
            for d in docs:
                data = d.to_dict()
                data['id'] = d.id
                res.append(data)
            return res

        path = f"{parent_col}/{parent_id}/{sub_col}"
        user_data = self.memory_store.setdefault(user_id, {})
        col_data = user_data.setdefault(path, {})
        return list(col_data.values())

    def preload_default_categories(self, user_id: str):
        existing = self.get_collection(user_id, 'categories')
        if not existing:
            for cat in DEFAULT_CATEGORIES:
                self.add_doc(user_id, 'categories', cat)

store = FirestoreStore()
